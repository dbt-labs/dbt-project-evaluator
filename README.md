This project is intended to be a dbt proect with poor DAG modeling so the professional services team can develop tools to detect these errors

### Types of DAG issues to potentially detect:

  - __Direct Join to Source__: a model has a reference to both a model and a source
  - __Source Fanout__: a source is used in multiple models
  - __Multiple Sources Joined__: a model references more than one source
  - __Rejoining of Upstream Concepts__: a circular reference is created in the DAG

![image](https://user-images.githubusercontent.com/73915542/148579991-c7135cd7-6302-48f9-8c64-5f3a9b8cc992.png)
