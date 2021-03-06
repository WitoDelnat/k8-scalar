## Disclaimer for external users

We are still in the process of making the code of Scalar publicly available. 
Right now, in order to compile a Scalar experiment you first need to to add the [scalar-1.0.0.jar](../../development/scalar/target/)
 as a Maven dependency in the [pom.xml file](../../development/scalar/pom.xml). 

JavaDoc documentation is available at https://distrinet.cs.kuleuven.be/software/scalar/scalar-doc/index.html

## Scalar development workflow
Open the project in Eclipse. Click on project -> Configure -> Convert to Maven project. All dependencies are managed via Maven
To execute a dummy Scalar experiment on your local machine, you can start Scalar with the default `experiment.properties` and `platform.properties` 
configuration files. Start the Jave class Launcher.class in Eclipse with as command-line arguments `conf/platform.properties` and `conf/experiment.properties`.


You also compile the Scalar code at the command line with `mvn package`.  You execute the dummy Scalar experiment as 
```
java -jar target/scalar-1.0.0.jar conf/platform.properties conf/experiment.properties
```

To include Scalar in your own Maven project, you can use the `scalar-project-pom.xml` as a template 
The source code does also include unit tests that coverage most of Scalar's functionality 

To develop a particular workload type, you have to design different subclasses of the `be.kuleuven.distrinet.scalar.core.User` and `be.kuleuven.distrinet.scalar.core.Request classes`.  
The [following paper](./heyman_preuveneers_joosen.pdf) illustrates in detail how to implemnt such User and Request classes
You can also take a look at the implementation of the Cassandra..User and Cassandra..Request classes [here](../../development/scalar/src/be/kuleuven/distrinet/scalar/
)
