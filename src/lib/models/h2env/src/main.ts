import { Dynamo } from 'dynamodb-onetable/Dynamo'
import { Model, Table } from 'dynamodb-onetable'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
const Match = {
  ulid: /^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}$/,
  email: /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
  name: /^[a-z0-9 ,.'-]+$/i,
  address: /[a-z0-9 ,.-]+$/,
  zip: /^\d{5}(?:[-\s]\d{4})?$/,
  phone: /^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$/,
};
const client = new Dynamo({ client: new DynamoDBClient({ region: "us-east-1" }) });

const H2Schema = {
  format: 'onetable:1.1.0',
  version: '1.0.0',
  indexes: {
    primary: { hash: 'PK', sort: 'SK' },
    gs1: { hash: 'gs1pk', sort: 'gs1sk', project: ['gs1pk', 'gs1sk'] },
    gs2: { hash: 'gs2pk', sort: 'gs2sk', project: ['gs2pk', 'gs2sk'] },
    ls1: { sort: 'id', type: 'local' },
  },
  models: {
    Env: {
      PK: { type: String, value: 'env#${id}' },
      SK: { type: String, value: 'env#' },
      id: { type: String, generate: 'ulid', validate: /^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}$/i },
      owner: { type: String, required: true },
      subnet: { type: Number, required: true },
      tracking: { type: Array, items: { type: String, validate: /(?:https?):\/\/(\w+:?\w*)?(\S+)(:\d+)?(\/|\/([\w#!:.?+=&%!\-\/]))?/ }, required: true },
      status: { type: String, required: true, default: 'onboarding', enum: ['active', 'onboarding', 'ended'] },
      gs1pk: { type: String, value: 'env#' },
      gs1sk: { type: String, value: 'env#${owner}${id}' },
      gs2pk: { type: String, value: 'env#' },
      gs2sk: { type: Number, value: '${subnet}' }
    }
  } as const,
  params: {
    isoDates: true,
    timestamps: true
  }
};

const table = new Table({
  client: client,
  name: 'h2env',
  partial: false,
  schema: H2Schema,
});

export default table;