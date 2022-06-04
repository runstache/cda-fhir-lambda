FROM amazon/aws-lambda-python as base

RUN yum update -y
RUN yum upgrade -y

# Add Java and validator
RUN yum install java-11-amazon-corretto-headless -y
RUN yum install wget -y
RUN wget https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar

FROM base

# COPY MAPPING FILES
COPY ./mapping $LAMBDA_TASK_ROOT

# COPY LAMBDA FILES
COPY ./src/*.py $LAMBDA_TASK_ROOT

CMD ["lambda_function.run"]
