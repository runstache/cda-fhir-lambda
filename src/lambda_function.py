'''
Lambda Function for transforming CDA to FHIR
'''
import boto3
from boto3 import Session
from botocore.exceptions import ClientError
import os
import logging

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_session() -> Session:
    '''
    Creates an AWS Session.
    '''
    
    session = boto3.Session(region_name='us-east-1')
    return session

def get_object(bucket:str, key:str) -> dict:
    '''
    Retrieves the given S3 Object based on provided bucket and key.
    '''
    
    session = get_session()
    client = session.client('s3')
    
    try:
        response = client.get_object(Bucket=bucket, Key=key)
        return response
    except ClientError as e:
        logger.info('FAILED TO RETRIEVE OBJECT')
        raise e

def put_object(bucket:str, key:str, content:str):
    '''
    Places an Object into S3
    '''
    
    session = get_session()
    client = session.client('s3')
    
    try:
        client.put_object(Bucket=bucket, Key=key, Body=content.encode())
    except ClientError as e:
        logger.error('FAILED TO UPLOAD ITEM')
        raise e
    
def run(event, context):
    '''
    Main lambda function.
    '''
    
    if 'Records' in event:
        for record in event['Records']:
            s3_bucket = record['s3']['bucket']['name']
            s3_key = record['s3']['object']['key']
            
            response = get_object(s3_bucket, s3_key)
            
            if 'Body' in response:
                content = response['Body'].read().decode('utf-8')
                file_name = os.path.basename(s3_key)
                
                with open('/tmp/' + file_name, 'w', encoding='utf-8') as cda_file:
                    cda_file.write(content)
                
                # Run the Validator to transform from the mapping
                command = f"java -jar validator_cli.jar /tmp/{file_name} -ouput /tmp/bundle.json -transfom http://hl7.org/fhir/tutorial -ig ./logical -ig ./mapping -version 4.0.1"
                
                os.system(command)
                
                if os.path.exists('/tmp/bundle.json'):
                    # Send the Bundle to S3
                    new_key = f"fhir/cda/{file_name}.fhir.json"
                    
                    with open('/tmp/bundle.json', 'r', encoding='utf-8') as bundle_file:
                        fhir_content = bundle_file.read()
                        put_object(s3_bucket, new_key, fhir_content)
    logger.info('DONE')
                        
                        
                        
                    
