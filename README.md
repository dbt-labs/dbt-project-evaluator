This project is intended to be a dbt proect with poor DAG modeling so the professional services team can develop tools to detect these errors

### Types of DAG issues to potentially detect:

  - __Direct Join to Source__: a model has a reference to both a model and a source
  - __Source Fanout__: a source is used in multiple models
  - __Multiple Sources Joined__: a model references more than one source
  - __Rejoining of Upstream Concepts__: a circular reference is created in the DAG


<img width="999" alt="Screen Shot 2022-01-10 at 1 27 20 PM" src="https://user-images.githubusercontent.com/53586774/148968091-8c9cfc06-5f26-4938-8a0d-8d7abb72ce8d.png">
