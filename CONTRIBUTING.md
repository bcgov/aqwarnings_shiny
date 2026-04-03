## How to contribute

Government employees, public and members of the private sector are encouraged to contribute to the repository by *
*forking and submitting a pull request**.

(If you are new to GitHub, you might start with a [basic tutorial](https://help.github.com/articles/set-up-git) and
check out a more detailed guide to [pull requests](https://help.github.com/articles/using-pull-requests/).)

Pull requests will be evaluated by the repository guardians on a schedule and if deemed beneficial will be committed to
the master.

All contributors retain the original copyright to their stuff, but by contributing to this project, you grant a
world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users **under the terms of
the license under which this project is distributed.**

## Development

### Variable Naming Conventions

To improve readability and clarity within the QMardkown templates, we have adopted the following naming conventions for variables:

-  Variable names should be in `snake_case` in `R` code.  
-  prefix variables used as local intermediate results with `local_` to
   emphasize that they are not intended for use outside of the chunk.
-  prefix all global reference data with `reference_`
-  for document-scoped variables, prefix them with one of `data_` (for
   structured data and lists), `numeric_`, `string_` (for direct
   inclusion in output, usually), or `markup_` indicating their intended use.

---
*This project was created using the [bcgovr](https://github.com/bcgov/bcgovr) package.*
