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
RUN wget https://github.com/hapifhir/org.hl7.fhir.core/releases/download/5.6.47/validator_cli.jar

FROM base

# COPY MAPPING FILES
COPY ./mapping $LAMBDA_TASK_ROOT/mapping
COPY ./logical $LAMBDA_TASK_ROOT/logical


# Pull the NPM Packages for the Items
# Forces the validator to pre-download the items, doesn't do any actual processing
RUN export output=$(java -jar validator_cli.jar -ig ./mapping/  -ig ./logical/ -version 4.0.1) \
    && export output=''

# COPY LAMBDA FILES
COPY ./src/*.py $LAMBDA_TASK_ROOT

CMD ["lambda_function.run"]
