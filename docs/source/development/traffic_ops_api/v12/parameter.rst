.. 
.. Copyright 2015 Comcast Cable Communications Management, LLC
.. 
.. Licensed under the Apache License, Version 2.0 (the "License");
.. you may not use this file except in compliance with the License.
.. You may obtain a copy of the License at
.. 
..     http://www.apache.org/licenses/LICENSE-2.0
.. 
.. Unless required by applicable law or agreed to in writing, software
.. distributed under the License is distributed on an "AS IS" BASIS,
.. WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
.. See the License for the specific language governing permissions and
.. limitations under the License.
.. 

.. _to-api-v12-parameter:

Parameter
=========

.. _to-api-v12-parameters-route:

/api/1.2/parameters
+++++++++++++++++++

**GET /api/1.2/parameters**

  Authentication Required: Yes

  Role(s) Required: None

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  | ``last_updated`` | string  | The Time / Date this server entry was last updated                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | boolean | When true, the parameter is accessible only by admin users. Defaults to false. |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Response Example** ::

    {
     "response": [
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "foo.bar.net",
           "name": "domain_name",
           "config_file": "FooConfig.xml"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "0,1,2,3,4,5,6",
           "name": "Drive_Letters",
           "config_file": "storage.config"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": true,
           "value": "STRING __HOSTNAME__",
           "name": "CONFIG proxy.config.proxy_name",
           "config_file": "records.config"
        }
     ],
    }

|

**GET /api/1.2/parameters/:id**

  Authentication Required: Yes

  Role(s) Required: if secure of the parameter fetched is 1, require admin role, or any valid role can access.

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  | ``id``           | integer | The parameter index                                                            |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | boolean | When true, the parameter is accessible only by admin users. Defaults to false. |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Response Example** ::

    {
      "response": [
          {
              "last_updated": "2012-09-17 21:41:22",
              "secure": 0,
              "value": "foo.bar.net",
              "name": "domain_name",
              "id": "27",
              "config_file": "FooConfig.xml",
          }
      ]
    }

|

**GET /api/1.2/profiles/:id/parameters**

  Authentication Required: Yes

  Role(s) Required: None

  **Request Route Parameters**

  +------------------+----------+-----------------------+
  |       Name       | Required | Description           |
  +==================+==========+=======================+
  | ``id``           | yes      | Profile id            |
  +------------------+----------+-----------------------+

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  | ``last_updated`` | string  | The Time / Date this server entry was last updated                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | boolean | When true, the parameter is accessible only by admin users. Defaults to false. |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Response Example** ::

    {
     "response": [
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "foo.bar.net",
           "name": "domain_name",
           "config_file": "FooConfig.xml"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "0,1,2,3,4,5,6",
           "name": "Drive_Letters",
           "config_file": "storage.config"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": true,
           "value": "STRING __HOSTNAME__",
           "name": "CONFIG proxy.config.proxy_name",
           "config_file": "records.config"
        }
     ],
    }

|

**GET /api/1.2/profiles/name/:name/parameters**

  Authentication Required: Yes

  Role(s) Required: None

  **Request Route Parameters**

  +------------------+----------+-----------------------+
  |       Name       | Required | Description           |
  +==================+==========+=======================+
  | ``name``         | yes      | Profile name          |
  +------------------+----------+-----------------------+

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  | ``last_updated`` | string  | The Time / Date this server entry was last updated                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | boolean | When true, the parameter is accessible only by admin users. Defaults to false. |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Response Example** ::

    {
     "response": [
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "foo.bar.net",
           "name": "domain_name",
           "config_file": "FooConfig.xml"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": false,
           "value": "0,1,2,3,4,5,6",
           "name": "Drive_Letters",
           "config_file": "storage.config"
        },
        {
           "last_updated": "2012-09-17 21:41:22",
           "secure": true,
           "value": "STRING __HOSTNAME__",
           "name": "CONFIG proxy.config.proxy_name",
           "config_file": "records.config"
        }
     ],
    }

|

**POST /api/1.2/parameters**
  Create parameters.

  Authentication Required: Yes

  Role(s) Required: admin or oper

  **Request Route Parameters**
  The request route parameters accept 2 formats, both single paramter and parameters array formats are acceptable.

  single parameter format:

  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | Name           | Required | Type    | Description                                                                          |
  +================+==========+=========+======================================================================================+
  | ``name``       | yes      | string  | parameter name                                                                       |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``configFile`` | yes      | string  | parameter config_file                                                                |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``value``      | yes      | string  | parameter value                                                                      |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``secure``     | yes      | integer | secure flag, when 1, the parameter is accessible only by admin users. Defaults to 0. |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+

  parameters array format:

  +-----------------+----------+---------+--------------------------------------------------------------------------------------+
  | Name            | Required | Type    | Description                                                                          |
  +=================+==========+=========+======================================================================================+
  |                 | yes      | array   | parameters array                                                                     |
  +-----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``>name``       | yes      | string  | parameter name                                                                       |
  +-----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``>configFile`` | yes      | string  | parameter config_file                                                                |
  +-----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``>value``      | yes      | string  | parameter value                                                                      |
  +-----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``>secure``     | yes      | integer | secure flag, when 1, the parameter is accessible only by admin users. Defaults to 0. |
  +-----------------+----------+---------+--------------------------------------------------------------------------------------+

  **Response Properties**

  +-----------------+---------+--------------------------------------------------------------------------------------+
  | Parameter       | Type    | Description                                                                          |
  +=================+=========+======================================================================================+
  |                 | array   | parameters array                                                                     |
  +-----------------+---------+--------------------------------------------------------------------------------------+
  | ``>id``         | integer | The parameter id                                                                     |
  +-----------------+---------+--------------------------------------------------------------------------------------+
  | ``>name``       | string  | parameter name                                                                       |
  +-----------------+---------+--------------------------------------------------------------------------------------+
  | ``>configFile`` | string  | parameter config_file                                                                |
  +-----------------+---------+--------------------------------------------------------------------------------------+
  | ``>value``      | string  | parameter value                                                                      |
  +-----------------+---------+--------------------------------------------------------------------------------------+
  | ``>secure``     | integer | secure flag, when 1, the parameter is accessible only by admin users. Defaults to 0. |
  +-----------------+---------+--------------------------------------------------------------------------------------+

  
  **Request Example** ::

  1. single parameter format exampe:
    {
        "name":"param1",
        "configFile":"configFile1"
        "value":"value1",
        "secure":0,
    }

  2. array format example:
    [
        {
            "name":"param1",
            "configFile":"configFile1"
            "value":"value1",
            "secure":0,
        }, 
        {
            "name":"param2",
            "configFile":"configFile2"
            "value":"value2",
            "secure":1,
        }
    ]

  **Response Example** ::

    {
        "response": [
           {
               "value":"value1",
               "secure":0,
               "name":"param1",
               "id":"1139",
               "configFile":"configFile1"
           },
           {
               "value":"value2",
               "secure":1,
               "name":"param2",
               "id":"1140",
               "configFile":"configFile2"
           }
       ]
    }

|

**PUT /api/1.2/parameters/{:id}**
  Edit parameter.

  Authentication Required: Yes

  Role(s) Required: if the parameter's secure equals 1, only admin role can edit the parameter, or admin or oper role can access the API.

  **Request Parameters**

  +-----------+---------+------------------+
  | Parameter | Type    | Description      |
  +===========+=========+==================+
  | ``id``    | integer | The parameter id |
  +-----------+---------+------------------+

  **Request Route Parameters**

  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | Name           | Required | Type    | Description                                                                          |
  +================+==========+=========+======================================================================================+
  | ``name``       | no       | string  | parameter name                                                                       |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``configFile`` | no       | string  | parameter config_file                                                                |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``value``      | no       | string  | parameter value                                                                      |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+
  | ``secure``     | no       | integer | secure flag, when 1, the parameter is accessible only by admin users. Defaults to 0. |
  +----------------+----------+---------+--------------------------------------------------------------------------------------+

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  |   ``id``         | integer | The parameter id                                                               |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | integer | When 1, the parameter is accessible only by admin users. Defaults to 0.        |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Request Example** ::

    {
        "name":"param1",
        "configFile":"configFile1"
        "value":"value1",
        "secure":"0",
    }

  **Response Example** ::

    {
     "response": {
        "value":"value1",
        "secure":"0",
        "name":"param1",
        "id":"1134",
        "configFile":"configFile1"
        }
    }

|

**DELETE /api/1.2/parameters/{:id}**
  delete parameter. If the parameter have profile associated, can not be deleted.

  Authentication Required: Yes

  Role(s) Required: admin or oper role

  **Request Parameters**

  +-----------+---------+------------------+
  | Parameter | Type    | Description      |
  +===========+=========+==================+
  | ``id``    | integer | The parameter id |
  +-----------+---------+------------------+

  **No Request Route Parameters**

  **Response Properties**

  +-------------+--------+----------------------------------+
  |  Parameter  |  Type  |           Description            |
  +=============+========+==================================+
  | ``alerts``  | array  | A collection of alert messages.  |
  +-------------+--------+----------------------------------+
  | ``>level``  | string | Success, info, warning or error. |
  +-------------+--------+----------------------------------+
  | ``>text``   | string | Alert message.                   |
  +-------------+--------+----------------------------------+
  | ``version`` | string |                                  |
  +-------------+--------+----------------------------------+

  **Response Example** ::

    Response Example:

    {
      "alerts":
        [
          { 
            "level": "success",
            "text": "Parameter was successfully deleted."
          }
        ],
    }

|

**POST /api/1.2/parameters/validate**
  Validate if the parameter exists.

  Authentication Required: Yes

  Role(s) Required: None

  **Request Route Parameters**

  +----------------+----------+--------------------------------+
  | Name           | Required | Type   | Description           |
  +================+==========+================================+
  | ``name``       | yes      | string | parameter name        |
  +----------------+----------+--------------------------------+
  | ``configFile`` | yes      | string | parameter config_file |
  +----------------+----------+--------------------------------+
  | ``value``      | yes      | string | parameter value       |
  +----------------+----------+--------------------------------+

  **Response Properties**

  +------------------+---------+--------------------------------------------------------------------------------+
  |    Parameter     |  Type   |                    Description                                                 |
  +==================+=========+================================================================================+
  |   ``id``         | integer | The parameter id                                                               |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``secure``       | integer | When 1, the parameter is accessible only by admin users. Defaults to 0.        |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``value``        | string  | The parameter value, only visible to admin if secure is true                   |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``name``         | string  | The parameter name                                                             |
  +------------------+---------+--------------------------------------------------------------------------------+
  | ``config_file``  | string  | The parameter config_file                                                      |
  +------------------+---------+--------------------------------------------------------------------------------+

  **Request Example** ::

    {
        "name":"param1",
        "configFile":"configFile1"
        "value":"value1",
    }

  **Response Example** ::

    {
     "response": {
        "value":"value1",
        "secure":"0",
        "name":"param1",
        "id":"1134",
        "configFile":"configFile1"
        }
    }

|

