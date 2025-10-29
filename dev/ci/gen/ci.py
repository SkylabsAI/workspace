import argparse
from arghandler import subcmd, ArgumentHandler

from dataclasses import dataclass
from collections import defaultdict
from enum import Enum

import git, git.exc, git.repo, git.repo.fun
import gitdb, gitdb.exc
import os
import sys
import pexpect
import asyncio

from async_property import async_cached_property

import httpx
import gidgethub.httpx

import logging

logger = logging.getLogger("helper")
log_format = '%(asctime)s %(name)-12s %(levelname)-8s %(message)s'

def reconfigure_logging(level):
    logging.basicConfig(
        level = logging.INFO,
        format = log_format,
        force = True
    )
reconfigure_logging(logging.INFO)



GITHUB_ORGA="SkylabsAI"
WORKSPACE_REPO="workspace"
GITHUB_SSH_URL_PREFIX="git@github.com:"

class Label(str, Enum):
    NO_SAME_BRANCH="No-Same-Branch"
    NO_COMPARE="No-Compare"

@dataclass(kw_only=True)
class Labels:
    same_branch : bool
    compare : bool
    @classmethod
    def defaults(cls):
        return cls(same_branch=True, compare=True)
    @classmethod
    def of_str(cls, label_str):
        labels = label_str.strip().split(",")
        return cls.of_set(labels)
    @classmethod
    def of_set(cls, labels):
        res = cls.defaults()
        for x in labels:
            match x.strip():
                case Label.NO_SAME_BRANCH:
                    res.same_branch = False
                case Label.NO_COMPARE:
                    res.compare = False
        return res

@dataclass(kw_only=True)
class Hashes:
    job : str # the hash we are testing in this job
    ref : str | None # an optional reference hash used for performance comparisons
    @classmethod
    def of_branch(cls,repo, branch):
        return cls(target=repo.branch_hash(branch),mr_branch=None,merge_base=None)
    @classmethod
    def default(cls, repo):
        return cls.of_branch(repo, repo.default_branch)

@dataclass(frozen=True, kw_only=True)
class Repo:
    orga_path : str
    url : str
    default_branch : str
    dir_path : str # relative to workspace root

    @classmethod
    def of_args(cls,args):
        args = {f : getattr(args, f"repo_{f}") for f in cls.__dataclass_fields__.keys()}
        cls(**args)
    @property
    def github_path(self):
        path = self.url.split("github.com")[-1]
        # for ssh urls
        path = path.removeprefix(":")
        # for http urls
        path = path.removeprefix("/")
        # for both, possibly
        path = path.removesuffix(".git")
        return path
    @property
    def git_repo(self):
        return git.Repo(os.path.join(os.getcwd(), self.dir_path))
    def ensure_fetched(self, obj, depth=None):
        if isinstance(obj, str) and obj.startswith("origin/"):
            obj = obj.removeprefix("origin/")
        try:
            self.git_repo.remotes.origin.fetch(obj, verbose=False, depth=depth)
        except git.exc.GitCommandError:
            logger.warning(f"Unable to fetch {obj}")
    @property
    def branches(self):
        return list(map(lambda rr: rr.path, self.git_repo.remotes.origin.refs))
    def has_branch(self, branch):
        return f"refs/remotes/origin/{branch}" in self.branches
    def has_commit(self, commit):
        try:
            self.git_repo.commit(commit)
            return True
        except Exception:
            return False
    def has_ref(self, ref):
        # TODO this is ugly
        return self.has_commit(ref) or self.has_branch(ref)
    def branch_hash(self, branch):
        try:
            return git.repo.fun.name_to_object(self.git_repo, branch, return_ref=False)
        except gitdb.exc.BadName:
            return None
    # picks the first branch or hash out of [choices] that exists in the repo
    def first_choice(self, choices):
        for choice in choices:
            match self.branch_hash(choice):
                case None: continue
                case obj: return obj

    def uniq_merge_base(self, *args):
        for arg in args:
            self.ensure_fetched(arg)
        choices = self.git_repo.merge_base(*args)
        match choices:
            case []: raise Exception(f"No merge in {self.dir_path} base(s) for {args}.")
            case [base]: return str(base)
            case ls: raise Exception(f"Too many merge bases in {self.dir_path} for {args}: {ls}")

    @classmethod
    def of_loop_echo(cls, loop_echo_line):
        (orga_path, url, default_branch, dir_path) = loop_echo_line.strip().split(" ")
        return Repo(orga_path=orga_path, url=url, default_branch=default_branch, dir_path=dir_path)

    def commit_of(self, obj):
        return self.git_repo.commit(obj).hexsha

@dataclass(kw_only=True)
class Repos:
    repos : list[Repo]
    def __iter__(self):
        return self.repos.__iter__()
    @classmethod
    def of_loop_echo(cls, loop_echo_lines):
        repos = list(map(Repo.of_loop_echo, loop_echo_lines))
        return cls(repos=repos)
    @classmethod
    def make(cls):
        # TODO: ensure cloned deps
        output = pexpect.run("bash -c 'make show-config | sort'")
        # logger.debug(f"make loop out: {output}")
        output = output.decode('utf-8')
        return cls.of_loop_echo(output.splitlines())
    def find_github_path(self, github_path, _default_branch: str):
        for repo in self.repos:
            if repo.github_path == github_path:
                return repo
        return None
    @property
    def workspace(self):
        return self.find_github_path(self, f"{GITHUB_ORGA}/{WORKSPACE_REPO}")

class EventType(Enum):
    PUSH = 0
    PULL_REQUEST = 1
    @staticmethod
    def of_type(ty):
        match ty.upper():
            case "PUSH": return EventType.PUSH
            case "PULL_REQUEST": return EventType.PULL_REQUEST

class AmbiguousBranchPRs(Exception):
    def __init__(self, github_path, branch, PRs):
        self.github_path = github_path
        self.branch = branch
        self.PRs = PRs

## gidgethub + aiohttp

class GithubSingleton:
    def __init__(self):
        self.auth = None
        self.h = httpx.AsyncClient()
        self._g : gidgethub.httpx.GitHubAPI | None = None
        self.memoize = defaultdict(dict);
    @property
    def g(self) -> gidgethub.httpx.GitHubAPI :
        if (self._g == None):
            self._g = gidgethub.httpx.GitHubAPI(self.h, "skylabs-ci-helper",oauth_token=self.auth)
        return self._g
    def set_auth(self, auth):
        self.auth = auth
    async def pr(self, repo, number):
        key = (repo,number)
        if key in self.memoize["pr"]:
            return self.memoize["pr"][key]
        resource = f"/repos/{repo}/pulls/{number}"
        pr = await self.g.getitem(resource)
        self.memoize["pr"][key] = pr
        return pr

    async def branch_pr(self, repo, branch):
        key = (repo,branch)
        if key in self.memoize["branch_pr"]:
            return self.memoize["branch_pr"][key]
        head = f"{GITHUB_ORGA}:{branch}"
        url = f"/repos/{repo}/pulls?head={head}"
        # logger.debug(f"gitdgethub: Attempting to get paginated results for url {url}")
        prs = self.g.getiter(f"/repos/{repo}/pulls?head={head}")
        uniq_pr = None
        async for pr in prs:
            if uniq_pr != None:
                raise AmbiguousBranchPRs(repo, branch, [uniq_pr, pr])
            uniq_pr = pr
        self.memoize["branch_pr"][key] = uniq_pr
        return uniq_pr
    async def has_pr(self, repo, branch):
        return await self.branch_pr(repo,branch) == None

GH = GithubSingleton()

@dataclass(kw_only=True)
class PRData:
    number : int
    head_ref : str
    base_ref : str
    mergeable : bool | None     # can be null in github's API
    merge_commit : str | None
    labels : Labels

    @classmethod
    def of_api_response(cls, response):
        has_mergeable = "mergeable" in response
        mergeable = response["mergeable"] if has_mergeable else False
        return cls(number=response["number"],
            head_ref=response["head"]["ref"],
            base_ref=response["base"]["ref"],
            mergeable=mergeable,
            merge_commit=response["merge_commit_sha"] if mergeable else None,
            labels=Labels.of_set(map(lambda x: x["name"], response["labels"])),
            )

# per-repo Data
@dataclass(kw_only=True)
class RepoData:
    pr : PRData | None
    job_branch : str | None # this is always a branch name but not necessarily an unambiguous reference; does not include [origin/] prefix
    job_ref : str | None # this can be a commit in the case of the trigger and also whenever we run pull_request pipelines where the actual code might be a merge commit of job_branch and the target
    base_ref : str | None

    @classmethod
    def empty(cls):
        kwargs = {f : None for f in cls.__dataclass_fields__.keys()}
        return cls(**kwargs)

class ReposData:
    def __init__(self):
        self.data = {}
    def __getitem__(self, repo):
        if not (repo in self.data):
            self.data[repo] = RepoData.empty()
        return self.data[repo]

    def print(self):
        for r in self.data:
            print(f"{r}: {self.data[r]}")

    async def workspace_job_ref(self, trigger):
        ws = Workspace().repo
        data = self[ws]
        if data.job_ref != None:
            return data.job_ref
        if trigger.repo == ws:
            logger.info(f"Pipeline triggered on {WORKSPACE_REPO}")
            logger.info(f"Using trigger commit {trigger.commit}")
            data.job_ref = trigger.commit
        elif trigger.labels.same_branch:
            logger.info(f"Pipeline trigger from outside of {WORKSPACE_REPO} with {Label.NO_SAME_BRANCH} enabled")
            job_choices = await self.job_choices(trigger, ws)
            logger.info(f"Choices for {WORKSPACE_REPO} in order of priority: {job_choices}")
            choice = git_first_existing_choice(ws, job_choices)
            logger.info(f"Using first existing choice for {WORKSPACE_REPO}: {choice}")
            data.job_ref = choice
        else:
            logger.info(f"Pipeline trigger from outside of {WORKSPACE_REPO} without {Label.NO_SAME_BRANCH} ")
            default = ws.default_branch
            logger.info(f"Using default branch {default}")
            data.job_ref = default
        return data.job_ref


    # compute the branch names/hashes to try based on the trigger configuration
    async def job_choices(self, trigger, repo):
        if trigger.is_trigger_repo(repo):
            return [trigger.branch]
        # all other repos get the default branch as a fallback
        if trigger.event_type == EventType.PULL_REQUEST and trigger.labels.same_branch:
            # if same-branch is set, the trigger branch name is our first choice
            nondefault_pr_base = await trigger.non_default_trigger_pr_base
            if nondefault_pr_base:
                # if the base of the trigger PR is not the repo's default branch, the base becomes a valid second choice for all other repos
                return [trigger.branch, nondefault_pr_base, repo.default_branch]
            return [trigger.branch, repo.default_branch]
        # without same branch we just pick the default branch of the current repo
        return [repo.default_branch]

    async def compute_job_refs(self, trigger, repos):
        choices = await asyncio.gather(*map(lambda r: self.job_choices(trigger, r), repos))
        for (repo, cs) in zip(repos, choices):
            data = self[repo]
            branch = git_first_existing_choice(repo, cs)
            data.job_branch = branch
            if trigger.is_trigger_repo(repo):
                # for the triggering repo, the trigger commit is the most precise ref we have
                # it will also already be a merge commit for pull_request triggers
                assert (trigger.branch in cs)
                data.job_ref = trigger.commit
            elif trigger.event_type == EventType.PULL_REQUEST and branch == trigger.branch:
                pr = await self.pr(repo, branch=branch)
                if pr != None and pr.mergeable:
                    repo.git_repo.remotes.origin.fetch(pr.merge_commit) # we don't get merge commits automatically
                    data.job_ref = pr.merge_commit
                elif pr != None:
                    status = "the mergeability of the PR has not yet been computed by GitHub" if pr.mergeable == None else "GitHub reports that the branch cannot be merged without conflicts"
                    logger.warning(f"Repo {repo.github_path} has a PR for {data.job_branch} but {status}. Falling back to {data.job_branch}.")
                    data.job_ref = f"origin/{data.job_branch}"
                else:
                    logger.warning(f"Repo {repo.github_path} has a branch {trigger.branch} but no PR exists for it. Cannot determine merge commit. Falling back to {data.job_branch}.")
                    data.job_ref = f"origin/{data.job_branch}"
            else:
                data.job_ref = f"origin/{data.job_branch}"

    # base ref of pr or default branch
    async def pr_base_ref(self, repo):
        base_ref = None
        branch = self[repo].job_branch
        pr = await self.pr(repo, branch=branch)
        if pr != None:
            return f"origin/{pr.base_ref}"
        else:
            return f"origin/{repo.default_branch}"

    # needs to run after [compute_job_refs]
    async def base_ref(self, trigger, repo):
        data = self[repo]
        job_ref = data.job_ref
        job_branch = data.job_branch
        if data.base_ref != None:
            return data.base_ref
        assert (job_branch != None)
        assert (job_ref != None)
        nondefault_pr_base = await trigger.non_default_trigger_pr_base
        if trigger.repo == repo:
            base_ref = await self.pr_base_ref(repo)
            merge_base = repo.uniq_merge_base(base_ref, job_ref)
            logger.info(f"{repo.github_path}: Using merge base of {base_ref} and job ref {job_ref}: {merge_base}")
            data.base_ref = merge_base
        elif trigger.labels.same_branch and job_branch == trigger.branch:
            base_ref = await self.pr_base_ref(repo)
            merge_base = repo.uniq_merge_base(base_ref, job_ref)
            logger.info(f"{repo.github_path}: Using merge base of {base_ref} and job ref {job_ref}: {merge_base}")
            data.base_ref = merge_base
        elif trigger.labels.same_branch and job_branch == nondefault_pr_base:
            data.base_ref = job_branch # = nondefault_pr_base
        else:
            # whatever we used for the main job, we'll use it for the comparison base
            data.base_ref = job_ref
        return data.base_ref


    async def workspace_base_ref(self, trigger):
        return await self.base_ref(trigger, Workspace().repo)

    async def compute_base_refs(self, trigger, repos):
        for repo in repos:
            await self.base_ref(trigger, repo)

    async def check_invariants(self, trigger, repos):
        fail = False
        same_branch_repos = [r for r in repos if self[r].job_branch == trigger.branch]
        if trigger.non_default_trigger_pr_base:
            missing_prs : list[Repo] = []
            wrong_targets : dict[Repo,PRData] = {}
            for repo in same_branch_repos:
                pr = await self.pr(repo, branch=trigger.branch)
                generic_msg = f"All repos participating in a {Label.NO_SAME_BRANCH} pipeline with a custom target branch must have PRs open with the same target branch."
                if pr == None:
                    missing_prs.append(repo)
                else:
                    trigger_pr = (await self.pr(trigger.repo)) # guaranteed != None but the typechecker does not know
                    if trigger_pr != None and pr.base_ref != trigger_pr.base_ref:
                        wrong_targets[repo] = pr

            for repo in missing_prs:
                logger.error(f"Repo {repo.github_path} has a branch {trigger.branch} but does not have PR. {generic_msg}")
                fail = True
            for repo, pr in wrong_targets.items():
                logger.error(f"Repo {repo.github_path} has a branch {trigger.branch} and PR {pr.number} but the PR's target branch is {pr.base_ref}, not {trigger.branch}. {generic_msg}")
                fail = True

        if trigger.event_type == EventType.PULL_REQUEST:
            missing_prs_and_not_rebased = []
            prs_not_mergeable  = {}
            for repo in same_branch_repos:
                pr = await self.pr(repo, branch=trigger.branch)
                generic_msg = f"All repos participating in a {Label.NO_SAME_BRANCH} \"pull_request\" pipeline with must each have either mergeable PRs or the triggering PR must target the default branch and the participating PR is fully rebased on its own default branch."
                if pr == None and not repo.git_repo.is_ancestor(repo.git_repo.commit(repo.default_branch), repo.git_repo.commit(self[repo].job_ref)):
                    missing_prs_and_not_rebased.append(repo)
                elif pr != None and pr.mergeable != True:
                    prs_not_mergeable[repo] = pr
            for repo in missing_prs_and_not_rebased:
                logger.error(f"Repo {repo.github_path} has a branch {trigger.branch} without a PR but the branch is not rebased on the repository's default branch {repo.default_branch}. {generic_msg}")
                fail = True
            for repo in prs_not_mergeable:
                pr = prs_not_mergeable[repo]
                status = "the mergeability of the PR has not yet been computed by GitHub" if pr.mergeable == None else "GitHub reports that the branch cannot be merged without conflicts"
                logger.error(f"Repo {repo.github_path} has a branch {trigger.branch} and PR {pr.number} but {status}. {generic_msg}")
                fail = True

        if fail:
            raise Exception("Invariants violated. See error messages above.")

    async def pr(self, repo : Repo, branch : str | None = None, initial_pr_number : int | None = None) -> PRData | None:
        data = self[repo]
        if isinstance(data.pr, PRData):
            return data.pr
        elif branch != None and branch == repo.default_branch:
            # There should not be pipelines running against the default branch that have an associated PR
            return None
        elif branch == None and initial_pr_number == None:
            raise Exception(f"Trying to find PR for repo {repo.github_path}: Either [branch] or [initial_pr_number] are required")
        elif branch != None and initial_pr_number == None:
            gh_pr = await GH.branch_pr(repo.github_path, branch)
            if gh_pr != None:
                data.pr = PRData.of_api_response(gh_pr)
                initial_pr_number = data.pr.number
            else:
                logger.warning(f"Repo {repo.github_path}: Unable to find PR for branch {branch}")
                return None
        assert (initial_pr_number != None)
        gh_pr = await GH.pr(repo.github_path, initial_pr_number)
        if gh_pr != None:
            data.pr = PRData.of_api_response(gh_pr)
        else:
            logger.error(f"Repo {repo.github_path}: Unable to find PR #{initial_pr_number}")
            exit(1)
        return data.pr

    def output_job_refs(self, fname, repos):
        with open(fname, 'w') as f:
            for r in repos:
                f.write(f"{r.dir_path}: {r.commit_of(self[r].job_ref)}\n")
    def output_base_refs(self, fname, repos):
        with open(fname, 'w') as f:
            for r in repos:
                if self[r].base_ref == None:
                    logger.warning(f"Repo {r.github_path} does not have a base commit.")
                    continue
                f.write(f"{r.dir_path}: {r.commit_of(self[r].base_ref)}\n")


DATA = ReposData()

@dataclass(kw_only=True)
class Trigger:
    repo : Repo
    pr : PRData | None
    branch : str
    commit : str
    event_type : EventType
    labels : Labels | None
    default_branch : str | None
    @classmethod
    async def of_args(cls, repo_by_path, args):
        args = {f : getattr(args,f"trigger_{f}") if hasattr(args,f"trigger_{f}") else None for f in cls.__dataclass_fields__.keys()}
        if "labels" not in args:
            args["labels"] = None # too hard to get via cmdline
        default_branch = args["default_branch"] if args["default_branch"] != None else "<stub>"
        repo = repo_by_path(args["repo"], default_branch)
        args["repo"] = repo
        pr_given = args["pr"] != None
        pr = await DATA.pr(repo, branch=args["branch"], initial_pr_number=args["pr"])
        if pr != None:
            args["pr"] = pr.number
        trigger = cls(**args)
        if trigger.labels == None:
            # We assume that we only have labels if a PR was given in the triggering event
            await trigger.backfill_labels()
        if trigger.event_type == EventType.PUSH and trigger.branch == trigger.repo.default_branch:
            # Disable comparison for pushes to default branches
            trigger.labels.compare = False
        if trigger.event_type == EventType.PUSH and trigger.branch != trigger.repo.default_branch:
            # Abort early for pushes to non-default branches
            logger.error("Push pipelines to non-default branches are not currently supoorted")
        return trigger

    def is_trigger_repo(self, other_repo):
        return self.repo == other_repo

    @async_cached_property
    async def pr_obj(self):
        return await DATA.pr(self.repo)

    async def backfill_labels(self):
        if self.labels != None:
            return
        if self.pr == None:
            logger.warning(f"Neither labels nor a PR were given via cmdline arguments. Assuming empty label set. Use --trigger-labels='' to silence this warning.")
            self.labels = Labels.defaults()
            return
        self.labels = (await self.pr_obj).labels

    @async_cached_property
    async def non_default_trigger_pr_base(self):
        if self.pr == None: return False
        pr = await GH.branch_pr(self.repo.github_path, self.pr)
        if pr == None: return False
        if self.repo.default_branch != pr["base"]:
            return pr["base"]

def non_empty_str(val): return val if val else None

def log_level(level_str):
    level = logging.getLevelName(level_str)
    reconfigure_logging(level=level)
    return level_str

def add_common_args(parser):
    parser.add_argument("--debug-level", choices=['DEBUG', 'INFO', 'WARN', 'ERROR'], type=log_level, default='INFO')
    parser.add_argument("--trigger-repo", help="The GitHub path of the repository triggering the current pipeline. Format: USER_OR_ORG/REPO_NAME", required=True, type=str)
    parser.add_argument("--trigger-event-type", help="The event type", required=True, type=EventType.of_type)
    parser.add_argument("--trigger-pr", help="The PR triggering this pipeline, if any. Considered missing if empty. Default: Retrieved via Github API.", required=False, type=non_empty_str)
    parser.add_argument("--trigger-branch", help="The branch on which the pipeline was triggered.", required=True, type=str)
    parser.add_argument("--trigger-default-branch", help="The default branch of the repository on which the pipeline was triggered.", required=True, type=non_empty_str)
    parser.add_argument("--trigger-commit", help="The commit that triggered this pipeline", required=True, type=str)
    parser.add_argument("--trigger-labels", help="Labels of the triggering PR. Default: Retrieved via Github API.", type=Labels.of_str)
    parser.add_argument("--github-token", type=(lambda x: GH.set_auth(x)), required=True)
    parser.add_argument("--output-file-job", type=str, default="job.txt")
    parser.add_argument("--output-file-base", type=str, default="base.txt")

class Workspace():
    _singleton = None
    @staticmethod
    def __new__(cls):
        if Workspace._singleton == None:
            _singleton = super().__new__(cls)
        return _singleton

    def __init__(self):
        output = pexpect.run(f"bash -c 'make show-config | grep -E \"^{GITHUB_ORGA}/{WORKSPACE_REPO} \"'")
        output = output.decode('utf-8')
        workspace_repo = Repo.of_loop_echo(output.splitlines()[0])
        self.repo = workspace_repo


def git_first_existing_choice(git_repo, choices):
    for c in choices:
        if git_repo.has_ref(c):
            return c
    raise Exception(f"Repo {git_repo.github_path} has none of the following branch choices: {choices}")

# checkout workspace for job build (not the reference)
async def checkout_workspace_job(trigger):
    job_ref = await DATA.workspace_job_ref(trigger)
    workspace_git = git.Repo(Workspace().repo.dir_path)
    logger.info(f"Checking out {Workspace().repo}")
    Workspace().repo.ensure_fetched(job_ref, depth=None)
    workspace_git.git.checkout(job_ref)

async def make_checkout_workspace(parser, context, args):
    add_common_args(parser)
    # add_loop_args(parser)
    args = parser.parse_args(args)
    # the triggering repo might not exist in workspace/main
    # we produce a stub just to construct a full Trigger object
    def repo_by_path(path, default_branch: str = "<stub>"):
        if path == f"{GITHUB_ORGA}/{WORKSPACE_REPO}":
            # We are in the workspace so we can ask the workspace to give us info about the workspace
            return Workspace().repo
        else:
            return Repo(orga_path="<stub>", url=f"{GITHUB_SSH_URL_PREFIX}{path}.git", default_branch=default_branch, dir_path="<stub>")
    trigger = await Trigger.of_args(repo_by_path, args)
    await checkout_workspace_job(trigger)

@subcmd(help="Checkout workspace at whatever initial commit is sensible for the current pipeline. WARNING: This needs to be run in a separate step because it is supposed to be able to change the very file it is defined in and thus affect the outcome of the remaining steps.")
def checkout_workspace(*args):
    logger.info("Checking out ")
    asyncio.run(make_checkout_workspace(*args))

async def make_config(parser, context, args):
    add_common_args(parser)
    # add_loop_args(parser)
    args = parser.parse_args(args)
    repos = Repos.make()
    trigger = await Trigger.of_args(repos.find_github_path, args)
    await DATA.workspace_job_ref(trigger) # just to initialize everything
    await DATA.compute_job_refs(trigger, repos.repos)
    DATA.print()
    DATA.output_job_refs(args.output_file_job, repos.repos)

    await DATA.check_invariants(trigger, repos.repos)

    if trigger.labels.compare:
        base = await DATA.workspace_base_ref(trigger)
        workspace_git = git.Repo(Workspace().repo.dir_path)
        workspace_git.git.checkout(base)
        repos = Repos.make()
        await DATA.compute_base_refs(trigger, repos.repos)
        DATA.print()
        DATA.output_base_refs(args.output_file_base, repos.repos)

    if GH.g != None and GH.g.rate_limit:
        logger.info(GH.g.rate_limit)
    else:
        logger.info("No API calls ran. Rate limit info not available.")


@subcmd(help="Compute the commits to be used for a CI job. TODO: output format, output file?")
def config(*args):
    asyncio.run(make_config(*args))

@subcmd(help="Read repo configuration from stdin")
def repos(parser, context, args):
    repos = Repos.make()

if __name__ == '__main__':
    # run the command - which will gather up all the subcommands
    handler = ArgumentHandler()
    handler.run()

