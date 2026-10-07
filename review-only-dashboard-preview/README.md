## ⚠️ Temporary - review only, not meant to stay

This folder holds a static HTML snapshot of the new dbt-charts dashboard
(`integrations/dbt_charts/charts/project_evaluator.yml`), one file per tab,
rendered via `dct render` so reviewers can see the actual output without
installing dbt-charts or standing up a warehouse connection themselves.

The data shown is from a synthetic stress-test project (not this package's
own integration tests) used to validate rendering and pagination at scale -
see the PR description for context. It is not meant to represent a real
evaluator run.

Download a file and open it locally in a browser (GitHub's raw view serves
HTML as plain text, so it won't render inline). This folder will be deleted
before merge.

- `overview.html` - the default landing tab
- `documentation.html`, `governance.html`, `modeling.html`, `performance.html`,
  `structure.html`, `testing.html` - the per-rule-category drill-down tabs
