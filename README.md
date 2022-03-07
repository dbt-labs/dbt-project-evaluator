This project is intended to be a dbt proect with poor DAG modeling so the professional services team can develop tools to detect these errors

### Types of DAG issues to potentially detect:

  - __Direct Join to Source__: a model has a reference to both a model and a source
  - __Source Fanout__: a source is used in multiple models
  - __Multiple Sources Joined__: a model references more than one source
  - __Rejoining of Upstream Concepts__: a circular reference is created in the DAG


![image](https://user-images.githubusercontent.com/53586774/157129634-98263607-7538-4b66-b424-4eaf9b34d58f.png)


### Limitation with BigQuery

BigQuery current support for recursive CTEs is limited. 

For BigQuery, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is defaulted to 9, which means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.
