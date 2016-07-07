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

.. _to-api-v12-server:

Server
======

.. _to-api-v12-servers-route:

/api/1.2/servers
++++++++++++++++

**GET /api/1.2/servers.json**

  Retrieves properties of CDN servers.

  Authentication Required: Yes

  Role(s) Required: None

  **Request Query Parameters**

  +-----------+----------+---------------------------------------------+
  |   Name    | Required |                Description                  |
  +===========+==========+=============================================+
  | ``dsId``  | no       | Used to filter servers by delivery service. |
  +-----------+----------+---------------------------------------------+
  | ``type``  | no       | Used to filter servers by type.             |
  +-----------+----------+---------------------------------------------+

  **Response Properties**

  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  |     Parameter      |  Type  |                                                Description                                                 |
  +====================+========+============================================================================================================+
  | ``cachegroup``     | string | The cache group name (see :ref:`to-api-v12-cachegroup`).                                                   |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``domainName``     | string | The domain name part of the FQDN of the cache.                                                             |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``hostName``       | string | The host name part of the cache.                                                                           |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``id``             | string | The server id (database row number).                                                                       |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``iloIpAddress``   | string | The IPv4 address of the lights-out-management port.                                                        |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``iloIpGateway``   | string | The IPv4 gateway address of the lights-out-management port.                                                |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``iloIpNetmask``   | string | The IPv4 netmask of the lights-out-management port.                                                        |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``iloPassword``    | string | The password of the of the lights-out-management user (displays as ****** unless you are an 'admin' user). |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``iloUsername``    | string | The user name for lights-out-management.                                                                   |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``interfaceMtu``   | string | The Maximum Transmission Unit (MTU) to configure for ``interfaceName``.                                    |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``interfaceName``  | string | The network interface name used for serving traffic.                                                       |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``ip6Address``     | string | The IPv6 address/netmask for ``interfaceName``.                                                            |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``ip6Gateway``     | string | The IPv6 gateway for ``interfaceName``.                                                                    |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``ipAddress``      | string | The IPv4 address for ``interfaceName``.                                                                    |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``ipGateway``      | string | The IPv4 gateway for ``interfaceName``.                                                                    |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``ipNetmask``      | string | The IPv4 netmask for ``interfaceName``.                                                                    |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``lastUpdated``    | string | The Time and Date for the last update for this server.                                                     |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpAddress``  | string | The IPv4 address of the management port (optional).                                                        |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpGateway``  | string | The IPv4 gateway of the management port (optional).                                                        |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpNetmask``  | string | The IPv4 netmask of the management port (optional).                                                        |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``physLocation``   | string | The physical location name (see :ref:`to-api-v12-phys-loc`).                                               |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``profile``        | string | The assigned profile name (see :ref:`to-api-v12-profile`).                                                 |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``rack``           | string | A string indicating rack location.                                                                         |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``routerHostName`` | string | The human readable name of the router.                                                                     |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``routerPortName`` | string | The human readable name of the router port.                                                                |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``status``         | string | The Status string (See :ref:`to-api-v12-status`).                                                          |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``tcpPort``        | string | The default TCP port on which the main application listens (80 for a cache in most cases).                 |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``type``           | string | The name of the type of this server (see :ref:`to-api-v12-type`).                                          |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``xmppId``         | string | Deprecated.                                                                                                |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+
  | ``xmppPasswd``     | string | Deprecated.                                                                                                |
  +--------------------+--------+------------------------------------------------------------------------------------------------------------+

  **Response Example** ::

   {
      "response": [
          {
              "cachegroup": "us-il-chicago",
              "domainName": "chi.kabletown.net",
              "hostName": "atsec-chi-00",
              "id": "19",
              "iloIpAddress": "172.16.2.6",
              "iloIpGateway": "172.16.2.1",
              "iloIpNetmask": "255.255.255.0",
              "iloPassword": "********",
              "iloUsername": "",
              "interfaceMtu": "9000",
              "interfaceName": "bond0",
              "ip6Address": "2033:D0D0:3300::2:2/64",
              "ip6Gateway": "2033:D0D0:3300::2:1",
              "ipAddress": "10.10.2.2",
              "ipGateway": "10.10.2.1",
              "ipNetmask": "255.255.255.0",
              "lastUpdated": "2015-03-08 15:57:32",
              "mgmtIpAddress": "",
              "mgmtIpGateway": "",
              "mgmtIpNetmask": "",
              "physLocation": "plocation-chi-1",
              "profile": "EDGE1_CDN1_421_SSL",
              "rack": "RR 119.02",
              "routerHostName": "rtr-chi.kabletown.net",
              "routerPortName": "2",
              "status": "ONLINE",
              "tcpPort": "80",
              "type": "EDGE",
              "xmppId": "atsec-chi-00-dummyxmpp",
              "xmppPasswd": "**********"
          },
          {
          ... more server data
          }
        ]
    }

|

**GET /api/1.2/servers/summary.json**

  Retrieves a count of CDN servers by type.

  Authentication Required: Yes

  Role(s) Required: None

  **Response Properties**

  +-----------+--------+------------------------------------------------------------------------+
  | Parameter |  Type  |                             Description                                |
  +===========+========+========================================================================+
  | ``count`` | int    | The number of servers of this type in this instance of Traffic Ops.    |
  +-----------+--------+------------------------------------------------------------------------+
  | ``type``  | string | The name of the type of the server count (see :ref:`to-api-v12-type`). |
  +-----------+--------+------------------------------------------------------------------------+

  **Response Example** ::

    {
      "response": [
        {
          "count": 4,
          "type": "CCR"
        },
        {
          "count": 55,
          "type": "EDGE"
        },
        {
          "type": "MID",
          "count": 18
        },
        {
          "count": 0,
          "type": "INFLUXDB"
        },
        {
          "count": 4,
          "type": "RASCAL"
        }
    }

|

**GET /api/1.2/servers/hostname/:name/details.json**

  Retrieves the details of a server.

  Authentication Required: Yes

  Role(s) Required: None

  **Request Route Parameters**

  +----------+----------+----------------------------------+
  |   Name   | Required |           Description            |
  +==========+==========+==================================+
  | ``name`` | yes      | The host name part of the cache. |
  +----------+----------+----------------------------------+

  **Response Properties**

  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  |      Parameter       |  Type  |                                                 Description                                                 |
  +======================+========+=============================================================================================================+
  | ``cachegroup``       | string | The cache group name (see :ref:`to-api-v12-cachegroup`).                                                    |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``deliveryservices`` | array  | Array of strings with the delivery service ids assigned (see :ref:`to-api-v12-ds`).                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``domainName``       | string | The domain name part of the FQDN of the cache.                                                              |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``hardwareInfo``     | hash   | Hwinfo struct (see :ref:`to-api-v12-hwinfo`).                                                               |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``hostName``         | string | The host name part of the cache.                                                                            |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``id``               | string | The server id (database row number).                                                                        |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``iloIpAddress``     | string | The IPv4 address of the lights-out-management port.                                                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``iloIpGateway``     | string | The IPv4 gateway address of the lights-out-management port.                                                 |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``iloIpNetmask``     | string | The IPv4 netmask of the lights-out-management port.                                                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``iloPassword``      | string | The password of the of the lights-out-management user  (displays as ****** unless you are an 'admin' user). |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``iloUsername``      | string | The user name for lights-out-management.                                                                    |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``interfaceMtu``     | string | The Maximum Transmission Unit (MTU) to configure for ``interfaceName``.                                     |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``interfaceName``    | string | The network interface name used for serving traffic.                                                        |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``ip6Address``       | string | The IPv6 address/netmask for ``interfaceName``.                                                             |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``ip6Gateway``       | string | The IPv6 gateway for ``interfaceName``.                                                                     |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``ipAddress``        | string | The IPv4 address for ``interfaceName``.                                                                     |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``ipGateway``        | string | The IPv4 gateway for ``interfaceName``.                                                                     |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``ipNetmask``        | string | The IPv4 netmask for ``interfaceName``.                                                                     |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``lastUpdated``      | string | The Time/Date of the last update for this server.                                                           |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpAddress``    | string | The IPv4 address of the management port (optional).                                                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpGateway``    | string | The IPv4 gateway of the management port (optional).                                                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``mgmtIpNetmask``    | string | The IPv4 netmask of the management port (optional).                                                         |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``physLocation``     | string | The physical location name (see :ref:`to-api-v12-phys-loc`).                                                |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``profile``          | string | The assigned profile name (see :ref:`to-api-v12-profile`).                                                  |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``rack``             | string | A string indicating rack location.                                                                          |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``routerHostName``   | string | The human readable name of the router.                                                                      |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``routerPortName``   | string | The human readable name of the router port.                                                                 |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``status``           | string | The Status string (See :ref:`to-api-v12-status`).                                                           |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``tcpPort``          | string | The default TCP port on which the main application listens (80 for a cache in most cases).                  |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``type``             | string | The name of the type of this server (see :ref:`to-api-v12-type`).                                           |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``xmppId``           | string | Deprecated.                                                                                                 |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+
  | ``xmppPasswd``       | string | Deprecated.                                                                                                 |
  +----------------------+--------+-------------------------------------------------------------------------------------------------------------+

  **Response Example** ::
   
    {
      "response": {
        "cachegroup": "us-il-chicago",
        "deliveryservices": [
          "1",
          "2",
          "3",
          "4"
        ],
        "domainName": "chi.kabletown.net",
        "hardwareInfo": {
          "Physical Disk 0:1:3": "D1S2",
          "Physical Disk 0:1:2": "D1S2",
          "Physical Disk 0:1:15": "D1S2",
          "Power Supply.Slot.2": "04.07.15",
          "Physical Disk 0:1:24": "YS08",
          "Physical Disk 0:1:1": "D1S2",
          "Model": "PowerEdge R720xd",
          "Physical Disk 0:1:22": "D1S2",
          "Physical Disk 0:1:18": "D1S2",
          "Enterprise UEFI Diagnostics": "4217A5",
          "Lifecycle Controller": "1.0.8.42",
          "Physical Disk 0:1:8": "D1S2",
          "Manufacturer": "Dell Inc.",
          "Physical Disk 0:1:6": "D1S2",
          "SysMemTotalSize": "196608",
          "PopulatedDIMMSlots": "24",
          "Physical Disk 0:1:20": "D1S2",
          "Intel(R) Ethernet 10G 2P X520 Adapter": "13.5.7",
          "Physical Disk 0:1:14": "D1S2",
          "BACKPLANE FIRMWARE": "1.00",
          "Dell OS Drivers Pack, 7.0.0.29, A00": "7.0.0.29",
          "Integrated Dell Remote Access Controller": "1.57.57",
          "Physical Disk 0:1:5": "D1S2",
          "ServiceTag": "D6XPDV1",
          "PowerState": "2",
          "Physical Disk 0:1:23": "D1S2",
          "Physical Disk 0:1:25": "D903",
          "BIOS": "1.3.6",
          "Physical Disk 0:1:12": "D1S2",
          "System CPLD": "1.0.3",
          "Physical Disk 0:1:4": "D1S2",
          "Physical Disk 0:1:0": "D1S2",
          "Power Supply.Slot.1": "04.07.15",
          "PERC H710P Mini": "21.0.2-0001",
          "PowerCap": "689",
          "Physical Disk 0:1:16": "D1S2",
          "Physical Disk 0:1:10": "D1S2",
          "Physical Disk 0:1:11": "D1S2",
          "Lifecycle Controller 2": "1.0.8.42",
          "BP12G+EXP 0:1": "1.07",
          "Physical Disk 0:1:9": "D1S2",
          "Physical Disk 0:1:17": "D1S2",
          "Broadcom Gigabit Ethernet BCM5720": "7.2.20",
          "Physical Disk 0:1:21": "D1S2",
          "Physical Disk 0:1:13": "D1S2",
          "Physical Disk 0:1:7": "D1S2",
          "Physical Disk 0:1:19": "D1S2"
        },
        "hostName": "atsec-chi-00",
        "id": "19",
        "iloIpAddress": "172.16.2.6",
        "iloIpGateway": "172.16.2.1",
        "iloIpNetmask": "255.255.255.0",
        "iloPassword": "********",
        "iloUsername": "",
        "interfaceMtu": "9000",
        "interfaceName": "bond0",
        "ip6Address": "2033:D0D0:3300::2:2/64",
        "ip6Gateway": "2033:D0D0:3300::2:1",
        "ipAddress": "10.10.2.2",
        "ipGateway": "10.10.2.1",
        "ipNetmask": "255.255.255.0",
        "mgmtIpAddress": "",
        "mgmtIpGateway": "",
        "mgmtIpNetmask": "",
        "physLocation": "plocation-chi-1",
        "profile": "EDGE1_CDN1_421_SSL",
        "rack": "RR 119.02",
        "routerHostName": "rtr-chi.kabletown.net",
        "routerPortName": "2",
        "status": "ONLINE",
        "tcpPort": "80",
        "type": "EDGE",
        "xmppId": "atsec-chi-00-dummyxmpp",
        "xmppPasswd": "X"

      }
    }

|

**POST /api/1.2/servercheck**

  Post a server check result to the serverchecks table.

  Authentication Required: Yes

  Role(s) Required: None

  **Request Route Parameters**

  +----------------------------+----------+-------------+
  |            Name            | Required | Description |
  +============================+==========+=============+
  | ``id``                     | yes      |             |
  +----------------------------+----------+-------------+
  | ``host_name``              | yes      |             |
  +----------------------------+----------+-------------+
  | ``servercheck_short_name`` | yes      |             |
  +----------------------------+----------+-------------+
  | ``value``                  | yes      |             |
  +----------------------------+----------+-------------+

  **Request Example** ::

    {
     "id": "",
     "host_name": "",
     "servercheck_short_name": "",
     "value": ""
    }

|

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
            "text": "Server Check was successfully updated."
          }
        ],
    }

|

**POST /api/1.2/servers**

  Allow user to create a server.

  Authentication Required: Yes

  Role(s) Required: admin or oper

  **Request Properties**

  +------------------+----------+------------------------------------------------+
  | Name             | Required | Description                                    |
  +==================+==========+================================================+
  | hostName         | yes      | The host name part of the server.              |
  +------------------+----------+------------------------------------------------+
  | domainName       | yes      | The domain name part of the FQDN of the cache. |
  +------------------+----------+------------------------------------------------+
  | cachegroup       | yes      | cache group name                               |
  +------------------+----------+------------------------------------------------+
  | interfaceName    | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipAddress        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipNetmask        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipGateway        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | interfaceMtu     | no       | 1500 or 9000                                   |
  +------------------+----------+------------------------------------------------+
  | physLocation     | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | type             | yes      | server type                                    |
  +------------------+----------+------------------------------------------------+
  | profile          | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | cdnName          | yes      | cdn name the server belongs to                 |
  +------------------+----------+------------------------------------------------+
  | tcpPort          | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | xmppId           | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | xmppPasswd       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | ip6Address       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | ip6Gateway       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | rack             | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpAddress    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpNetmask    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpGateway    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpAddress     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpNetmask     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpGateway     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloUsername      | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloPassword      | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | routerHostName   | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | routerPortName   | no       |                                                |
  +------------------+----------+------------------------------------------------+

  **Request Example** ::

    {
        "hostName": "tc1_ats1",
        "domainName": "my.test.com",
        "cachegroup": "cache_group_edge",
        "cdnName": "cdn_number_1",
        "interfaceName": "eth0",
        "ipAddress": "10.74.27.188",
        "ipNetmask": "255.255.255.0",
        "ipGateway": "10.74.27.1",
        "interfaceMtu": "1500",
        "physLocation": "plocation-chi-1",
        "type": "EDGE",
        "profile": "EDGE1_CDN1_421"
    }

|

  **Response Properties**

  +------------------+--------+------------------------------------------------+
  | Name             | Type   | Description                                    |
  +==================+========+================================================+
  | hostName         | string | The host name part of the server.              |
  +------------------+--------+------------------------------------------------+
  | Name             | string | Description                                    |
  +------------------+--------+------------------------------------------------+
  | domainName       | string | The domain name part of the FQDN of the cache. |
  +------------------+--------+------------------------------------------------+
  | cachegroup       | string | cache group name                               |
  +------------------+--------+------------------------------------------------+
  | interfaceName    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipAddress        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipNetmask        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipGateway        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | interfaceMtu     | string | 1500 or 9000                                   |
  +------------------+--------+------------------------------------------------+
  | physLocation     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | type             | string | server type                                    |
  +------------------+--------+------------------------------------------------+
  | profile          | string |                                                |
  +------------------+--------+------------------------------------------------+
  | cdnName          | string | cdn name the server belongs to                 |
  +------------------+--------+------------------------------------------------+
  | tcpPort          | string |                                                |
  +------------------+--------+------------------------------------------------+
  | xmppId           | string |                                                |
  +------------------+--------+------------------------------------------------+
  | xmppPasswd       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ip6Address       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ip6Gateway       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | rack             | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpAddress    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpNetmask    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpGateway    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpAddress     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpNetmask     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpGateway     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloUsername      | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloPassword      | string |                                                |
  +------------------+--------+------------------------------------------------+
  | routerHostName   | string |                                                |
  +------------------+--------+------------------------------------------------+
  | routerPortName   | string |                                                |
  +------------------+--------+------------------------------------------------+

  **Response Example** ::

    {
        'response' : {
            'xmppPasswd' : '**********',
            'profile' : 'EDGE1_CDN1_421',
            'iloUsername' : null,
            'status' : 'REPORTED',
            'ipAddress' : '10.74.27.188',
            'cdnId' : '1',
            'physLocation' : 'plocation-chi-1',
            'cachegroup' : 'cache_group_edge',
            'interfaceName' : 'eth0',
            'ip6Gateway' : null,
            'iloPassword' : null,
            'id' : '1003',
            'routerPortName' : null,
            'lastUpdated' : '2016-01-25 14:16:16',
            'ipNetmask' : '255.255.255.0',
            'ipGateway' : '10.74.27.1',
            'tcpPort' : '80',
            'mgmtIpAddress' : null,
            'ip6Address' : null,
            'interfaceMtu' : '1500',
            'iloIpGateway' : null,
            'hostName' : 'tc1_ats1',
            'xmppId' : 'tc1_ats1',
            'rack' : null,
            'mgmtIpNetmask' : null,
            'iloIpAddress' : null,
            'mgmtIpGateway' : null,
            'type' : 'EDGE',
            'domainName' : 'my.test.com',
            'iloIpNetmask' : null,
            'routerHostName' : null
        }
    }

|

**PUT /api/1.2/servers/{:id}**

  Allow user to edit server through api.

  Authentication Required: Yes

  Role(s) Required: admin or oper

  **Request Route Parameters**

  +------+----------+-------------------------------+
  | Name | Required | Description                   |
  +======+==========+===============================+
  | id   | yes      | The id of the server to edit. |
  +------+----------+-------------------------------+

  **Request Properties**

  +------------------+----------+------------------------------------------------+
  | Name             | Required | Description                                    |
  +==================+==========+================================================+
  | hostName         | yes      | The host name part of the server.              |
  +------------------+----------+------------------------------------------------+
  | domainName       | yes      | The domain name part of the FQDN of the cache. |
  +------------------+----------+------------------------------------------------+
  | cachegroup       | yes      | cache group name                               |
  +------------------+----------+------------------------------------------------+
  | interfaceName    | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipAddress        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipNetmask        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | ipGateway        | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | interfaceMtu     | no       | 1500 or 9000                                   |
  +------------------+----------+------------------------------------------------+
  | physLocation     | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | type             | yes      | server type                                    |
  +------------------+----------+------------------------------------------------+
  | profile          | yes      |                                                |
  +------------------+----------+------------------------------------------------+
  | cdnName          | yes      | cdn name the server belongs to                 |
  +------------------+----------+------------------------------------------------+
  | tcpPort          | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | xmppId           | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | xmppPasswd       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | ip6Address       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | ip6Gateway       | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | rack             | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpAddress    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpNetmask    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | mgmtIpGateway    | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpAddress     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpNetmask     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloIpGateway     | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloUsername      | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | iloPassword      | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | routerHostName   | no       |                                                |
  +------------------+----------+------------------------------------------------+
  | routerPortName   | no       |                                                |
  +------------------+----------+------------------------------------------------+

  **Request Example** ::

    {
        "hostName": "tc1_ats2",
        "domainName": "my.test.com",
        "cachegroup": "cache_group_edge",
        "cdnName": "cdn_number_1",
        "interfaceName": "eth0",
        "ipAddress": "10.74.27.188",
        "ipNetmask": "255.255.255.0",
        "ipGateway": "10.74.27.1",
        "interfaceMtu": "1500",
        "physLocation": "plocation-chi-1",
        "type": "EDGE",
        "profile": "EDGE1_CDN1_421"
    }

|

  **Response Properties**

  +------------------+--------+------------------------------------------------+
  | Name             | Type   | Description                                    |
  +==================+========+================================================+
  | hostName         | string | The host name part of the server.              |
  +------------------+--------+------------------------------------------------+
  | Name             | string | Description                                    |
  +------------------+--------+------------------------------------------------+
  | domainName       | string | The domain name part of the FQDN of the cache. |
  +------------------+--------+------------------------------------------------+
  | cachegroup       | string | cache group name                               |
  +------------------+--------+------------------------------------------------+
  | interfaceName    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipAddress        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipNetmask        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ipGateway        | string |                                                |
  +------------------+--------+------------------------------------------------+
  | interfaceMtu     | string | 1500 or 9000                                   |
  +------------------+--------+------------------------------------------------+
  | physLocation     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | type             | string | server type                                    |
  +------------------+--------+------------------------------------------------+
  | profile          | string |                                                |
  +------------------+--------+------------------------------------------------+
  | cdnName          | string | cdn name the server belongs to                 |
  +------------------+--------+------------------------------------------------+
  | tcpPort          | string |                                                |
  +------------------+--------+------------------------------------------------+
  | xmppId           | string |                                                |
  +------------------+--------+------------------------------------------------+
  | xmppPasswd       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ip6Address       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | ip6Gateway       | string |                                                |
  +------------------+--------+------------------------------------------------+
  | rack             | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpAddress    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpNetmask    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | mgmtIpGateway    | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpAddress     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpNetmask     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloIpGateway     | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloUsername      | string |                                                |
  +------------------+--------+------------------------------------------------+
  | iloPassword      | string |                                                |
  +------------------+--------+------------------------------------------------+
  | routerHostName   | string |                                                |
  +------------------+--------+------------------------------------------------+
  | routerPortName   | string |                                                |
  +------------------+--------+------------------------------------------------+
  
  **Response Example** ::

    {
        'response' : {
            'xmppPasswd' : '**********',
            'profile' : 'EDGE1_CDN1_421',
            'iloUsername' : null,
            'status' : 'REPORTED',
            'ipAddress' : '10.74.27.188',
            'cdnId' : '1',
            'physLocation' : 'plocation-chi-1',
            'cachegroup' : 'cache_group_edge',
            'interfaceName' : 'eth0',
            'ip6Gateway' : null,
            'iloPassword' : null,
            'id' : '1003',
            'routerPortName' : null,
            'lastUpdated' : '2016-01-25 14:16:16',
            'ipNetmask' : '255.255.255.0',
            'ipGateway' : '10.74.27.1',
            'tcpPort' : '80',
            'mgmtIpAddress' : null,
            'ip6Address' : null,
            'interfaceMtu' : '1500',
            'iloIpGateway' : null,
            'hostName' : 'tc1_ats2',
            'xmppId' : 'tc1_ats1',
            'rack' : null,
            'mgmtIpNetmask' : null,
            'iloIpAddress' : null,
            'mgmtIpGateway' : null,
            'type' : 'EDGE',
            'domainName' : 'my.test.com',
            'iloIpNetmask' : null,
            'routerHostName' : null
        }
    }

|

**DELETE /api/1.2/servers/{:id}**

  Allow user to delete server through api.

  Authentication Required: Yes

  Role(s) Required: admin or oper

  **Request Route Parameters**

  +------+----------+---------------------------------+
  | Name | Required | Description                     |
  +======+==========+=================================+
  | id   | yes      | The id of the server to delete. |
  +------+----------+---------------------------------+
  
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

    {
          "alerts": [
                    {
                            "level": "success",
                            "text": "Server was deleted."
                    }
            ],
    }

|

**POST /api/1.2/servers/{:id}/queue_update**

  Queue or dequeue updates for a specific server.

  Authentication Required: Yes

  Role(s) Required: admin or oper

  **Request Route Parameters**

  +-----------+----------+------------------+
  | Name      | Required | Description      |
  +===========+==========+==================+
  | id        | yes      | the server id.   |
  +-----------+----------+------------------+

  **Request Properties**

  +--------------+---------+-----------------------------------------------+
  | Name         | Type    | Description                                   |
  +==============+=========+===============================================+
  | action       | string  | queue or dequeue                              |
  +--------------+---------+-----------------------------------------------+

  **Response Properties**

  +--------------+---------+-----------------------------------------------+
  | Name         | Type    | Description                                   |
  +==============+=========+===============================================+
  | action       | string  | The action processed, queue or dequeue.       |
  +--------------+---------+-----------------------------------------------+
  | serverId     | integer | server id                                     |
  +--------------+---------+-----------------------------------------------+

  **Response Example** ::

    {
      "response": {
          "serverId": "1",
          "action": "queue" 
      }
    }

|

