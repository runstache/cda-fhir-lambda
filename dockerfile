FROM amazon/aws-lambda-python as base

RUN yum update -y
RUN yum upgrade -y

# Install Python Packages
COPY requirements.txt $LAMBDA_TASK_ROOT
WORKDIR $LAMBDA_TASK_ROOT

RUN pip install -r requirements.txt

# Add Java and validator
RUN yum install java-11-amazon-corretto-headless -y
RUN yum install wget -y
RUN wget https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar

FROM base

# COPY MAPPING FILES
COPY ./mapping $LAMBDA_TASK_ROOT

# COMPILE THE MAPPING FILES (Add more lines per file)
RUN java -jar validator_cli.jar -ig ./mapping/mapping.map  -compile ./mapping/mapping.map -version 4.0 -output ./mapping/mapping.json

# COPY LAMBDA FILES
COPY ./src/*.py $LAMBDA_TASK_ROOT

CMD ["lambda_function.run"]
