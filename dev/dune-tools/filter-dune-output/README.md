Filtering Dune Output
=====================

This package provides a program called `filter-dune-output`, which filters the
input to remove lines forming minimal segments such that:
- the first line starts with: "Warning: cache store error",
- a line ends with "after executing",
- the last line ends with ")".

It is used to filter dune cache store errors in our CI.
