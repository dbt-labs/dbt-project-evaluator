This project is intended to be a dbt project with poor implementation of dbt features to create a suite of macros and models to detect areas for improvement.

## DAG auditing

The DAG auditing suite parses your project to find places where the relationships between models be violating dbt's best practices.  

### Types of DAG issues to potentially detect:

  - __Direct Join to Source__: a model has a reference to both a model and a source
  - __Source Fanout__: a source is used in multiple models
  - __Multiple Sources Joined__: a model references more than one source
  - __Rejoining of Upstream Concepts__: a circular reference is created in the DAG

![image](https://user-images.githubusercontent.com/73915542/148579991-c7135cd7-6302-48f9-8c64-5f3a9b8cc992.png)

## Test Usage + Coverage

The testing suite parses your project and checks for test coverage, test to model ratio, and untested nodes in your project. 


