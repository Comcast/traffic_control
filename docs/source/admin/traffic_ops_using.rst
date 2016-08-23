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

.. |graph| image:: ../../../traffic_ops/app/public/images/graph.png
.. |info| image:: ../../../traffic_ops/app/public/images/info.png
.. |checkmark| image:: ../../../traffic_ops/app/public/images/good.png
.. |X| image:: ../../../traffic_ops/app/public/images/bad.png
.. |clock| image:: ../../../traffic_ops/app/public/images/clock-black.png

Using Traffic Ops
%%%%%%%%%%%%%%%%%


The Traffic Ops Menu
====================

.. image:: 12m.png

The following tabs are available in the menu at the top of the Traffic Ops user interface.

.. index::
  Health Tab

* **Health**

  Information on the health of the system. Hover over this tab to get to the following options:

  +---------------+------------------------------------------------------------------------------------------------------------------------------------+
  |     Option    |                                                            Description                                                             |
  +===============+====================================================================================================================================+
  | Table View    | A real time view into the main performance indicators of the CDNs managed by Traffic Control.                                      |
  |               | This view is sourced directly by the Traffic Monitor data and is updated every 10 seconds.                                         |
  |               | This is the default screen of Traffic Ops.                                                                                         |
  |               | See :ref:`rl-health-table` for details.                                                                                            |
  +---------------+------------------------------------------------------------------------------------------------------------------------------------+
  | Graph View    | A real graphical time view into the main performance indicators of the CDNs managed by Traffic Control.                            |
  |               | This view is sourced by the Traffic Monitor data and is updated every 10 seconds.                                                  |
  |               | On loading, this screen will show a history of 24 hours of data from Traffic Stats                                                 |
  |               | See :ref:`rl-health-graph` for details.                                                                                            |
  +---------------+------------------------------------------------------------------------------------------------------------------------------------+
  | Server Checks | A table showing the results of the periodic check extension scripts that are run. See :ref:`rl-server-checks`                      |
  +---------------+------------------------------------------------------------------------------------------------------------------------------------+
  | Daily Summary | A graph displaying the daily peaks of bandwidth, overall bytes served per day, and overall bytes served since initial installation |
  |               | per CDN.                                                                                                                           |
  +---------------+------------------------------------------------------------------------------------------------------------------------------------+

* **Delivery Services**

  The main Delivery Service table. This is where you Create/Read/Update/Delete Delivery Services of all types. Hover over to get the following sub option:

  +-------------+--------------------------------------+
  |    Option   |             Description              |
  +=============+======================================+
  | Federations | Add/Edit/Delete Federation Mappings. |
  +-------------+--------------------------------------+

* **Servers**

  The main Servers table. This is where you Create/Read/Update/Delete servers of all types.  Click the main tab to get to the main table, and hover over to get these sub options:

  +-------------------+------------------------------------------------------------------------------------------+
  |       Option      |                                       Description                                        |
  +===================+==========================================================================================+
  | Upload Server CSV | Bulk add of servers from a csv file. See :ref:`rl-bulkserver`                            |
  +-------------------+------------------------------------------------------------------------------------------+

* **Parameters**

  Parameters and Profiles can be edited here. Hover over the tab to get the following options:

  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  |        Option       |                                                                             Description                                                                             |
  +=====================+=====================================================================================================================================================================+
  | Global Profile      | The table of global parameters. See :ref:`rl-param-prof`. This is where you Create/Read/Update/Delete parameters in the Global profile                              |
  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | All Cache Groups    | The table of all parameters *that are assgined to a cachegroup* - this may be slow to pull up, as there can be thousands of parameters.                             |
  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | All Profiles        | The table of all parameters *that are assgined to a profile* - this may be slow to pull up, as there can be thousands of parameters.                                |
  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | Select Profile      | Select the parameter list by profile first, then get a table of just the parameters for that profile.                                                               |
  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | Orphaned Parameters | A table of parameters that are not associated to any profile of cache group. These parameters either should be deleted or associated with a profile of cache group. |
  +---------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------+

* **Tools**

  Tools for working with Traffic Ops and it's servers. Hover over this tab to get the following options:

  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  |       Option       |                                                            Description                                                            |
  +====================+===================================================================================================================================+
  | Generate ISO       | Generate a bootable image for any of the servers in the Servers table (or any server for that matter). See :ref:`rl-generate-iso` |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  | Queue Updates      | Send Updates to the caches. See :ref:`rl-queue-updates`                                                                           |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  | DB Dump            | Backup the Database to a .sql file.                                                                                               |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  | Snapshot CRConfig  | Send updates to the Traffic Monitor / Traffic Router servers.  See :ref:`rl-queue-updates`                                        |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  | Invalidate Content | Invalidate or purge content from all caches in the CDN. See :ref:`rl-purge`                                                       |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+
  | Manage DNSSEC keys | Manage DNSSEC Keys for a chosen CDN.                                                                                              |
  +--------------------+-----------------------------------------------------------------------------------------------------------------------------------+


* **Misc**

  Miscellaneous editing options. Hover over this tab to get the following options:

  +--------------------+-------------------------------------------------------------------------------------------+
  |       Option       |                                        Description                                        |
  +====================+===========================================================================================+
  | Cache Groups       | Create/Read/Update/Delete cache groups                                                    |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Users              | Create/Read/Update/Delete users                                                           |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Profiles           | Create/Read/Update/Delete profiles. See :ref:`rl-working-with-profiles`                   |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Networks(ASNs)     | Create/Read/Update/Delete Autonomous System Numbers See :ref:`rl-asn-czf`                 |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Hardware           | Get detailed hardware information (note: this should be moved to a Traffic Ops Extension) |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Data Types         | Create/Read/Update/Delete data types                                                      |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Divisions          | Create/Read/Update/Delete divisions                                                       |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Regions            | Create/Read/Update/Delete regions                                                         |
  +--------------------+-------------------------------------------------------------------------------------------+
  | Physical Locations | Create/Read/Update/Delete locations                                                       |
  +--------------------+-------------------------------------------------------------------------------------------+

.. index::
  Change Log

* **ChangeLog**

  The Changelog table displays the changes that are being made to the Traffic Ops database through the Traffic Ops user interface. This tab will show the number of changes since you last visited this tab in (brackets) since the last time you visited this tab. There are currently no sub menus for this tab.


* **Help**

  Help for Traffic Ops and Traffic Control. Hover over this tab to get the following options:

  +---------------+---------------------------------------------------------------------+
  |     Option    |                             Description                             |
  +===============+=====================================================================+
  | About         | Traffic Ops information, such as version, database information, etc |
  +---------------+---------------------------------------------------------------------+
  | Release Notes | Release notes for the most recent releases of Traffic Ops           |
  +---------------+---------------------------------------------------------------------+
  | Logout        | Logout from Traffic Ops                                             |
  +---------------+---------------------------------------------------------------------+


.. index::
  Edge Health
  Health

Health
======

.. _rl-health-table:

The Health Table
++++++++++++++++
The Health table is the default landing screen for Traffic Ops, it displays the status of the EDGE caches in a table form directly from Traffic Monitor (bypassing Traffic Stats), sorted by Mbps Out. The columns in this table are:


* **Profile**: the Profile of this server or ALL, meaning this row shows data for multiple servers, and the row shows the sum of all values.
* **Host Name**: the host name of the server or ALL, meaning this row shows data for multiple servers, and the row shows the sum of all values.
* **Edge Cache Group**: the edge cache group short name or ALL, meaning this row shows data for multiple servers, and the row shows the sum of all values.
* **Healthy**: indicates if this cache is healthy according to the Health Protocol. A row with ALL in any of the columns will always show a |checkmark|, this column is valid only for individual EDGE caches.
* **Admin**: shows the administrative status of the server.
* **Connections**: the number of connections this cache (or group of caches) has open (``ats.proxy.process.http.current_client_connections`` from ATS).
* **Mbps Out**: the bandwidth being served out if this cache (or group of caches)

Since the top line has ALL, ALL, ALL, it shows the total connections and bandwidth for all caches managed by this instance of Traffic Ops.

.. _rl-health-graph:

Graph View
++++++++++
The Graph View shows a live view of the last 24 hours of bits per seconds served and open connections at the edge in a graph. This data is sourced from Traffic Stats. If there are 2 CDNs configured, this view will show the statistis for both, and the graphs are stacked. On the left-hand side, the totals and immediate values as well as the percentage of total possible capacity are displayed. This view is update every 10 seconds.


.. _rl-server-checks:

Server Checks
+++++++++++++
The server checks page is inteded to give an overview of the Servers managed by Traffic Control as well as their status. This data comes from `Traffic Ops extensions <traffic_ops_extensions.html>`_.

+------+-----------------------------------------------------------------------+
| Name |                 Description                                           |
+======+=======================================================================+
| ILO  | Ping the iLO interface for EDGE or MID servers                        |
+------+-----------------------------------------------------------------------+
| 10G  | Ping the IPv4 address of the EDGE or MID servers                      |
+------+-----------------------------------------------------------------------+
| 10G6 | Ping the IPv6 address of the EDGE or MID servers                      |
+------+-----------------------------------------------------------------------+
| MTU  | Ping the EDGE or MID using the configured MTU from Traffic Ops        |
+------+-----------------------------------------------------------------------+
| FQDN | DNS check that matches what the DNS servers responds with compared to |
|      | what Traffic Ops has.                                                 |
+------+-----------------------------------------------------------------------+
| DSCP | Checks the DSCP value of packets from the edge server to the Traffic  |
|      | Ops server.                                                           |
+------+-----------------------------------------------------------------------+
| RTR  | Content Router checks. Checks the health of the Content Routers.      |
|      | Checks the health of the caches using the Content Routers.            |
+------+-----------------------------------------------------------------------+
| CHR  | Cache Hit Ratio in percent.                                           |
+------+-----------------------------------------------------------------------+
| CDU  | Total Cache Disk Usage in percent.                                    |
+------+-----------------------------------------------------------------------+
| ORT  | Operational Readiness Test. Uses the ORT script on the edge and mid   |
|      | servers to determine if the configuration in Traffic Ops matches the  |
|      | configuration on the edge or mid. The user that this script runs as   |
|      | must have an ssh key on the edge servers.                             |
+------+-----------------------------------------------------------------------+

Daily Summary
+++++++++++++
Displays daily max gbps and bytes served for all CDNs.  In order for the graphs to appear, the 'daily_bw_url' and 'daily_served_url' parameters need to be be created, assigned to the global profile, and have a value of a grafana graph.  For more information on configuring grafana, see the `Traffic Stats <traffic_stats.html>`_  section.

.. _rl-server:

Server
======
This view shows a table of all the servers in Traffic Ops. The table columns show the most important details of the server. The **IPAddrr** column is clickable to launch an ``ssh://`` link to this server. The |graph| icon will link to a Traffic Stats graph of this server for caches, and the |info| will link to the server status pages for other server types.


Server Types
++++++++++++
These are the types of servers that can be managed in Traffic Ops:

+---------------+---------------------------------------------+
|      Name     |                 Description                 |
+===============+=============================================+
| EDGE          | Edge Cache                                  |
+---------------+---------------------------------------------+
| MID           | Mid Tier Cache                              |
+---------------+---------------------------------------------+
| ORG           | Origin                                      |
+---------------+---------------------------------------------+
| CCR           | Comcast Content Router                      |
+---------------+---------------------------------------------+
| RASCAL        | Rascal health polling & reporting           |
+---------------+---------------------------------------------+
| TOOLS_SERVER  | Ops hosts for managment                     |
+---------------+---------------------------------------------+
| RIAK          | Riak keystore                               |
+---------------+---------------------------------------------+
| SPLUNK        | SPLUNK indexer search head etc              |
+---------------+---------------------------------------------+
| TRAFFIC_STATS | traffic_stats server                        |
+---------------+---------------------------------------------+
| INFLUXDB      | influxDb server                             |
+---------------+---------------------------------------------+


.. index::
  Bulk Upload Server

.. _rl-bulkserver:

Bulk Upload Server
++++++++++++++++++



Delivery Service
================
The fields in the Delivery Service view are:

.. Sorry for the width of this table, don't know how to make the bullet lists work otherwise. Just set your monitor to 2560*1600, and put on your glasses.

+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                       Name                       |                                                                                                     Description                                                                                                     |
+==================================================+=====================================================================================================================================================================================================================+
| XML ID                                           | A unique string that identifies this delivery service.                                                                                                                                                              |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Content Routing Type                             | The type of content routing this delivery service will use. See :ref:`rl-ds-types`.                                                                                                                                 |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Protocol                                         | The protocol to serve this delivery service to the clients with:                                                                                                                                                    |
|                                                  |                                                                                                                                                                                                                     |
|                                                  | -  0 http                                                                                                                                                                                                           |
|                                                  | -  1 https                                                                                                                                                                                                          |
|                                                  | -  2 both http and https                                                                                                                                                                                            |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DSCP Tag                                         | The DSCP value to mark IP packets to the client with.                                                                                                                                                               |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Signed URLs                                      | Use Signed URLs? See :ref:`rl-signed-urls`.                                                                                                                                                                         |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Query String Handling                            | How to treat query strings:                                                                                                                                                                                         |
|                                                  |                                                                                                                                                                                                                     |
|                                                  | - 0 use in cache key and hand up to origin -this means each unique query string Is treated as a unique URL.                                                                                                         |
|                                                  | - 1 Do not use in cache key, but pass up to origin - this means a 2 URLs that are the same except for the query string will match, and cache HIT, while the origin still sees original query string in the request. |
|                                                  | - 2 Drop at edge - this means a 2 URLs that are the same except for  the query string will match, and cache HIT, while the origin will not see original query string in the request.                                |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Geo Limit?                                       | Some services are intended to be limited by geography. The possible settings are are:                                                                                                                               |
|                                                  |                                                                                                                                                                                                                     |
|                                                  | - None - Do not limit by geography.                                                                                                                                                                                 |
|                                                  | - CZF only - If the requesting IP is not in the Coverage Zone File, do not serve the request.                                                                                                                       |
|                                                  | - CZF + US - If the requesting IP is not in the Coverage Zone File or not in the United States, do not serve the request.                                                                                           |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Geo Limit Redirect URL                           | (for HTTP routed delivery services only) This is the URL Traffic Router will redirect to when Geo Limit Failure. See :ref:`geolimit-failure-redirect-feature`                                                       |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Bypass FQDN                                      | (for HTTP routed delivery services only) This is the FQDN Traffic Router will redirect to (with the same path) when the max Bps or Max Tps for this deliveryservice are exceeded.                                   |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Bypass Ipv4                                      | (For DNS routed delivery services only) This is the address to respond to A requests with when the the max Bps or Max Tps for this delivery service are exceeded.                                                   |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Bypass IPv6                                      | (For DNS routed delivery services only) This is the address to respond to AAAA requests with when the the max Bps or Max Tps for this delivery service are exceeded.                                                |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| IPv6 Routing Enabled?                            | When set to yes, the Traffic Router will respond to AAAA DNS requests for the tr. and edge. names of this delivery service. Otherwise, only A records will be served.                                               |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Range Request Handling                           | (experimental)  How to treat range requests:                                                                                                                                                                        |
|                                                  |                                                                                                                                                                                                                     |
|                                                  | - 0 Do not cache (ranges requested from files taht are already cached due to a non range request will be a HIT)                                                                                                     |
|                                                  | - 1 Use the `background_fetch <https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/background_fetch.en.html>`_ plugin.                                                                              |
|                                                  | - 2 Use the cache_range_requests plugin.                                                                                                                                                                            |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Delivery Service DNS TTL                         | The Time To Live on the DNS record for the Traffic Router A and AAAA records (``tr.<deliveryservice>.<cdn-domain>``) for a HTTP delivery service *or* for the A and                                                 |
|                                                  | AAAA records of the edge name (``edge.<deliveryservice>.<cdn-domain>``).                                                                                                                                            |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Origin Server Base URL                           | The Origin Server's base URL. This includes the protocol (http or https). Example: ``http://movies.origin.com``                                                                                                     |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Use Multi Site Origin Feature                    | Enable the Multi Site Origin feature for this delivery service. See :ref:`rl-multi-site-origin`                                                                                                                     |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Multi Site Origin Algorithm                      | - 1 Consistent Hash spreads requests across multiple parents simultaneously based on hash of content URL.                                                                                                           |
|                                                  | - 2 Strict Round Robin spreads requests across multiple parents simultaneously based on order of requests.                                                                                                          |
|                                                  | - 3 IP Based Round Robin spreads requests across multiple parents simultaneously based on order of requests, but ensures that requests from the same IP always go to the same parent if available.                  |
|                                                  | - 4 Latched uses only a single parent at any given time and switches to a new parent only if the current parent fails.                                                                                              |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| CCR profile                                      | The Traffic Router  profile for this delivery service. See :ref:`rl-ccr-profile`.                                                                                                                                   |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Maximum Bits per Second allowed globally         | The maximum bits per second this delivery service can serve across all EDGE caches before traffic will be diverted to the bypass destination. For a DNS delivery service, the Bypass Ipv4 or Ipv6  will be used     |
|                                                  | (depending on whether this was a A or AAAA request), and for HTTP delivery services the Bypass FQDN will be used.                                                                                                   |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Maximum Transactions per Second allowed globally | The maximum transactions per se this delivery service can serve across all EDGE caches before traffic will be diverted to the bypass destination. For a DNS delivery service, the Bypass Ipv4 or Ipv6  will be used |
|                                                  | (depending on whether this was a A or AAAA request), and for HTTP delivery services the Bypass FQDN will be used.                                                                                                   |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Geo Miss Default Latitude                        | Default Latitude for this delivery service. When client localization fails for bot Coverage Zone and Geo Lookup, this the client will be routed as if it was at this lat.                                           |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Geo Miss Default Longitude                       | Default Longitude for this delivery service. When client localization fails for bot Coverage Zone and Geo Lookup, this the client will be routed as if it was at this long.                                         |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Edge Header Rewrite Rules                        | Header Rewrite rules to apply for this delivery service at the EDGE tier. See :ref:`rl-header-rewrite`. [1]_                                                                                                        |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Mid Header Rewrite Rules                         | Header Rewrite rules to apply for this delivery service at the MID tier. See :ref:`rl-header-rewrite`. [1]_                                                                                                         |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Regex Remap Expression                           | Regex Remap rule to apply to this delivery service at the Edge tier. See `ATS documentation on regex_remap <https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/regex_remap.en.html>`_. [1]_        |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Cache URL expression                             | Cache URL rule to apply to this delivery service. See `ATS documentation on cacheurl <https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/cacheurl.en.html>`_. [1]_                                 |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Raw remap text                                   | For HTTP and DNS deliveryservices, this will get added to the end of the remap line on the cache verbatim. For ANY_MAP deliveryservices this is the remap line. [1]_                                                |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Long Description                                 | Long description for this delivery service. To be consumed from the APIs by downstream tools (Portal).                                                                                                              |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Customer                                         | Customer description for this delivery service. To be consumed from the APIs by downstream tools (Portal).                                                                                                          |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Service                                          | Service description for this delivery service. To be consumed from the APIs by downstream tools (Portal).                                                                                                           |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Info URL                                         | Info URL  for this delivery service. To be consumed from the APIs by downstream tools (Portal).                                                                                                                     |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Check Path                                       | A path (ex: /crossdomain.xml) to verify the connection to the origin server with. This can be used by Check Extension scripts to do periodic health checks against the delivery service.                            |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Origin Shield (Pipe Delimited String)            | Experimental. Origin Shield string.                                                                                                                                                                                 |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Active                                           | When this is set to no Traffic Router will not serve DNS or HTTP responses for this delivery service.                                                                                                               |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Last Updated                                     | (Read Only) The last time this delivery service was updated.                                                                                                                                                        |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Number of edges assigned                         | (Read Only - change by clicking the **Server Assignments** button at the bottom) The number of EDGE caches assigned to this delivery service. See :ref:`rl-assign-edges`.                                           |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Number of static DNS entries                     | (Read Only - change by clicking the **Static DNS** button at the bottom) The number of static DNS entries for this delivery service. See :ref:`rl-static-dns`.                                                      |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Example delivery URL                             | (Read Only) An example of how the delivery URL may start. This could be multiple rows if multiple HOST_REGEXP entries have been entered.                                                                            |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Regular expressions for this delivery service    | A subtable of the regular expressions to use when routing traffic for this delivery service. See :ref:`rl-ds-regexp`.                                                                                               |
+--------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

.. [1] These fields are not validated by Traffic Ops to be correct syntactically, and can cause Traffic Server to not start if invalid. Please use with caution.


.. index::
  Delivery Service Type

.. _rl-ds-types:

Delivery Service Types
++++++++++++++++++++++
One of the most important settings when creating the delivery service is the selection of the delivery service *type*. This type determines the routing method and the primary storage for the delivery service.

+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|       Name      |                                                                                                                                                         Description                                                                                                                                                          |
+=================+==============================================================================================================================================================================================================================================================================================================================+
| HTTP            | HTTP Content Routing  - The Traffic Router DNS auth server returns its own IP address on DNS queries, and the client gets redirected to a specific cache                                                                                                                                                                     |
|                 | in the nearest cache group using HTTP 302.  Use this for long sessions like HLS/HDS/Smooth live streaming, where a longer setup time is not a.                                                                                                                                                                               |
|                 | problem.                                                                                                                                                                                                                                                                                                                     |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DNS             | DNS Content Routing - The Traffic Router DNS auth server returns an edge cache IP address to the client right away. The client will find the cache quickly                                                                                                                                                                   |
|                 | but the Traffic Router can not route to a cache that already has this content in the cache group. Use this for smaller objects like web page images / objects.                                                                                                                                                               |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| HTTP_NO_CACHE   | HTTP Content Routing, but the caches will not actually cache the content, they act as just proxies. The MID tier is bypassed.                                                                                                                                                                                                |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| HTTP_LIVE       | HTTP Content routing, but where for "standard" HTTP content routing the objects are stored on disk, for this delivery service type the objects are stored                                                                                                                                                                    |
|                 | on the RAM disks. Use this for linear TV. The MID tier is bypassed for this type.                                                                                                                                                                                                                                            |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| HTTP_LIVE_NATNL | HTTP Content routing, same as HTTP_LIVE, but the MID tier is NOT bypassed.                                                                                                                                                                                                                                                   |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DNS_LIVE_NATNL  | DNS Content routing, ut where for "standard" DNS content routing the objects are stored on disk, for this delivery service type the objects are stored                                                                                                                                                                       |
|                 | on the RAM disks. Use this for linear TV. The MID tier is NOT bypassed for this type.                                                                                                                                                                                                                                        |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DNS_LIVE        | DNS Content routing, same as DNS_LIVE_NATIONAL, but the MID tier is bypassed.                                                                                                                                                                                                                                                |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| ANY_MAP         | ANY_MAP is not known to Traffic Router. For this deliveryservice, the "Raw remap text" field in the input form will be used as the remap line on the cache.                                                                                                                                                                  |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| STEERING        | The Delivery Service will be used to route to other delivery services.  The target delivery services Traffic Router and the routing weights for those delivery services will be defined by an admin or steering user.  For more information see the `steering feature <traffic_router.html#steering-feature>`_ documentation |
+-----------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+


.. Note:: Once created, the Traffic Ops user interface does not allow you to change the delivery service type; the drop down is greyed out. There are many things that can go wrong when changing the type, and it is safer to delete the delivery service, and recreate it.

Federations
+++++++++++
  Federations allow for other (federated) CDNs (at a different ISP, MSO, etc) to add a list of resolvers and a CNAME to a delivery service Traffic Ops.  When a request is made from one of federated CDN's clients, Traffic Router will return the CNAME configured in the federation mapping.  This allows the federated CDN to serve the content without the content provider changing the URL, or having to manage multiple URLs.

  Before adding a federation in the Traffic Ops UI, a user with the federations role needs to be created.  This user will be assigned to the federation and will be able to add resolvers to the federation via the Traffic Ops `Federation API <../development/traffic_ops_api/v12/federation.html>`_.

.. index::
  Header Rewrite

.. _rl-header-rewrite:

Header Rewrite Options and DSCP
+++++++++++++++++++++++++++++++
Most header manipulation and per-delivery service configuration overrides are done using the `ATS Header Rewrite Plugin <https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/header_rewrite.en.html>`_. Traffic Control allows you to enter header rewrite rules to be applied at the edge and at the mid level. The syntax used in Traffic Ops is the same as the one described in the ATS documentation, except for some special strings that will get replaced:

+-------------------+--------------------------+
| Traffic Ops Entry |    Gets Replaced with    |
+===================+==========================+
| __RETURN__        | A newline                |
+-------------------+--------------------------+
| __CACHE_IPV4__    | The cache's IPv4 address |
+-------------------+--------------------------+

The deliveryservice screen also allows you to set the DSCP value of traffic sent to the client. This setting also results in a header_rewrite rule to be generated and applied to at the edge.

.. Note:: The DSCP setting in the UI is *only* for setting traffic towards the client, and gets applied *after* the initial TCP handshake is complete, and the HTTP request is received (before that the cache can't determine what deliveryservice this request is for, and what DSCP to apply), so the DSCP feature can not be used for security settings - the TCP SYN-ACK is not going to be DSCP marked.


.. index::
  Token Based Authentication
  Signed URLs

.. _rl-signed-urls:

Token Based Authentication
++++++++++++++++++++++++++
Token based authentication or *signed URLs* is implemented using the Traffic Server ``url_sig`` plugin. To sign a URL at the signing portal take the full URL, without any query string, and add on a query string with the following parameters:

Client IP address
        The client IP address that this signature is valid for.

        ``C=<client IP address>``

Expiration
        The Expiration time (seconds since epoch) of this signature.

        ``E=<expiration time in secs since unix epoch>``

Algorithm
        The Algorithm used to create the signature. Only 1 (HMAC_SHA1)
        and 2 (HMAC_MD5) are supported at this time

        ``A=<algorithm number>``

Key index
        Index of the key used. This is the index of the key in the
        configuration file on the cache. The set of keys is a shared
        secret between the signing portal and the edge caches. There
        is one set of keys per reverse proxy domain (fqdn).

        ``K=<key index used>``
Parts
        Parts to use for the signature, always excluding the scheme
        (http://).  parts0 = fqdn, parts1..x is the directory parts
        of the path, if there are more parts to the path than letters
        in the parts param, the last one is repeated for those.
        Examples:

                1: use fqdn and all of URl path
                0110: use part1 and part 2 of path only
                01: use everything except the fqdn

        ``P=<parts string (0's and 1's>``

Signature
        The signature over the parts + the query string up to and
        including "S=".

        ``S=<signature>``

.. seealso:: The url_sig `README <https://github.com/apache/trafficserver/blob/master/plugins/experimental/url_sig/README>`_.

Generate URL Sig Keys
^^^^^^^^^^^^^^^^^^^^^
To generate a set of random signed url keys for this delivery service and store them in Traffic Vault, click the **Generate URL Sig Keys** button at the bottom of the delivery service details screen.


.. rl-parent-selection:

Parent Selection
++++++++++++++++

Parameters in the Edge (child) profile that influence this feature:

+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
|                      Name                     |    Filename    |    Default    |                      Description                      |
+===============================================+================+===============+=======================================================+
| CONFIG proxy.config.                          | records.config | INT 1         | enable parent selection.  This is a required setting. |
| http.parent_proxy_routing_enable              |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 1         | required for parent selection.                        |
| url_remap.remap_required                      |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 0         | See                                                   |
| http.no_dns_just_forward_to_parent            |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 1         |                                                       |
| http.uncacheable_requests_bypass_parent       |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 1         |                                                       |
| http.parent_proxy_routing_enable              |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 300       |                                                       |
| http.parent_proxy.retry_time                  |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 10        |                                                       |
| http.parent_proxy.fail_threshold              |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 4         |                                                       |
| http.parent_proxy.total_connect_attempts      |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 2         |                                                       |
| http.parent_proxy.per_parent_connect_attempts |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 30        |                                                       |
| http.parent_proxy.connect_attempts_timeout    |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 0         |                                                       |
| http.forward.proxy_auth_to_parent             |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 0         |                                                       |
| http.parent_proxy_routing_enable              |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | STRING        |                                                       |
| http.parent_proxy.file                        |                | parent.config |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| CONFIG proxy.config.                          | records.config | INT 3         |                                                       |
| http.parent_proxy.connect_attempts_timeout    |                |               |                                                       |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+
| algorithm                                     | parent.config  | urlhash       | The algorithm to use.                                 |
+-----------------------------------------------+----------------+---------------+-------------------------------------------------------+


Parameters in the Mid (parent) profile that influence this feature:

+----------------+---------------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|      Name      |    Filename   | Default |                                                                                    Description                                                                                    |
+================+===============+=========+===================================================================================================================================================================================+
| domain_name    | CRConfig.json | -       | Only parents with the same value as the edge are going to be used as parents (to keep separation between CDNs)                                                                    |
+----------------+---------------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| weight         | parent.config | 1.0     | The weight of this parent, translates to the number of replicas in the consistent hash ring. This parameter only has effect with algorithm at the client set to "consistent_hash" |
+----------------+---------------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| port           | parent.config | 80      | The port this parent is listening on as a forward proxy.                                                                                                                          |
+----------------+---------------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| use_ip_address | parent.config | 0       | 1 means use IP(v4) address of this parent in the parent.config, 0 means use the host_name.domain_name concatenation.                                                              |
+----------------+---------------+---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

.. _rl-multi-site-origin:

Multi Site Origin
+++++++++++++++++
.. Note:: The Multi Site Origin feature is based upon a feature n ATS that has yet to be submitted to Traffic Server upstream, until it is, set this to 0, or use the ATS rpm supplied on the traffic-control-cdn.net website.

Normally, the mid servers are not aware of any redundancy at the origin layer. With Multi Site Origin enabled this changes - Traffic Server (and Traffic Ops) are now made aware of the fact there are multiple origins, and can be configured to do more advanced failover and loadbalancing actions.

With This feature enabled, origin servers (or origin server VIP names for a site) are going to be entered as servers in to the Traiffic Ops UI. Server type is With This feature enabled, origin servers (or origin server VIP names for a site) are going to be entered as servers in to the Traiffic Ops UI. Server type is ""


Parameters in the Origin profile that influence this feature:

+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
|                                   Name                                   |    Filename    |  Default   |                                            Description                                             |
+==========================================================================+================+============+====================================================================================================+
| CONFIG proxy.config. http.parent_proxy_routing_enable                    | records.config | INT 1      | enable parent selection.  This is a required setting.                                              |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. url_remap.remap_required                            | records.config | INT 1      | required for parent selection.                                                                     |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_proxy.per_parent_connect_attempts       | records.config | INT 5      | maximum of 5 connection attempts per parent (parent.config list) within a transaction.             |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_proxy.total_connect_attempts            | records.config | INT 10     | maximum of 10 total connection attempts within a transaction.                                      |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_origin.simple_retry_enabled             | records.config | INT 1      | enables simple retry.                                                                              |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_origin.simple_retry_response_codes      | records.config | STRING 404 | the response code that invokes simple retry.  May be a comman separated list of response codes.    |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_origin.dead_server_retry_response_codes | records.config | STRING 503 | the response code that invokes dead server retry.  May be a comma separated list of response codes |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. http.parent_origin.dead_server_retry_enabled        | records.config | INT 1      | enables dead server retry.                                                                         |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+
| CONFIG proxy.config. diags.debug.enabled                                 | records.config | INT 1      | enable debugging for testing only                                                                  |
+--------------------------------------------------------------------------+----------------+------------+----------------------------------------------------------------------------------------------------+

see :ref:`rl-multi-site-origin-qht` for a *quick how to* on this feature.

.. _rl-ccr-profile:

CCR Profile or Traffic Router Profile
+++++++++++++++++++++++++++++++++++++

+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                   Name                  |      Config_file       |                                                                                                Description                                                                                                |
+=========================================+========================+===========================================================================================================================================================================================================+
| location                                | dns.zone               | Location to store the DNS zone files in the local file system of Traffic Router.                                                                                                                          |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| location                                | http-log4j.properties  | Location to find the log4j.properties file for Traffic Router.                                                                                                                                            |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| location                                | dns-log4j.properties   | Location to find the dns-log4j.properties file for Traffic Router.                                                                                                                                        |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| location                                | geolocation.properties | Location to find the log4j.properties file for Traffic Router.                                                                                                                                            |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| CDN_name                                | rascal-config.txt      | The human readable name of the CDN for this profile.                                                                                                                                                      |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| CoverageZoneJsonURL                     | CRConfig.xml           | The location (URL) to retrieve the coverage zone map file in JSON format from.                                                                                                                            |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| geolocation.polling.url                 | CRConfig.json          | The location (URL) to retrieve the geo database file from.                                                                                                                                                |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| geolocation.polling.interval            | CRConfig.json          | How often to refresh the coverage geo location database  in ms                                                                                                                                            |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| coveragezone.polling.interval           | CRConfig.json          | How often to refresh the coverage zone map in ms                                                                                                                                                          |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| coveragezone.polling.url                | CRConfig.json          | The location (URL) to retrieve the coverage zone map file in XML format from.                                                                                                                             |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| domain_name                             | CRConfig.json          | The top level domain of this Traffic Router instance.                                                                                                                                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.soa.expire                          | CRConfig.json          | The value for the expire field the Traffic Router DNS Server will respond with on Start of Authority (SOA) records.                                                                                       |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.soa.minimum                         | CRConfig.json          | The value for the minimum field the Traffic Router DNS Server will respond with on SOA records.                                                                                                           |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.soa.admin                           | CRConfig.json          | The DNS Start of Authority admin.  Should be a valid support email address for support if DNS is not working correctly.                                                                                   |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.soa.retry                           | CRConfig.json          | The value for the retry field the Traffic Router DNS Server will respond with on SOA records.                                                                                                             |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.soa.refresh                         | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on A records.                                                                                                                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.NS                             | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on NS records.                                                                                                                                    |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.SOA                            | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on SOA records.                                                                                                                                   |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.AAAA                           | CRConfig.json          | The Time To Live (TTL) the Traffic Router DNS Server will respond with on AAAA records.                                                                                                                   |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.A                              | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on A records.                                                                                                                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.DNSKEY                         | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on DNSKEY records.                                                                                                                                |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tld.ttls.DS                             | CRConfig.json          | The TTL the Traffic Router DNS Server will respond with on DS records.                                                                                                                                    |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| api.port                                | server.xml             | The TCP port Traffic Router listens on for API (REST) access.                                                                                                                                             |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| api.cache-control.max-age               | CRConfig.json          | The value of the ``Cache-Control: max-age=`` header in the API responses of Traffic Router.                                                                                                               |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| api.auth.url                            | CRConfig.json          | The API authentication URL (https://${tmHostname}/api/1.1/user/login); ${tmHostname} is a search and replace token used by Traffic Router to construct the correct URL)                                   |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| consistent.dns.routing                  | CRConfig.json          | Control whether DNS Delivery Services use consistent hashing on the edge FQDN to select caches for answers. May improve performance if set to true; defaults to false                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| dnssec.enabled                          | CRConfig.json          | Whether DNSSEC is enabled; this parameter is updated via the DNSSEC administration user interface.                                                                                                        |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| dnssec.allow.expired.keys               | CRConfig.json          | Allow Traffic Router to use expired DNSSEC keys to sign zones; default is true. This helps prevent DNSSEC related outages due to failed Traffic Control components or connectivity issues.                |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| dynamic.cache.primer.enabled            | CRConfig.json          | Allow Traffic Router to attempt to prime the dynamic zone cache; defaults to true                                                                                                                         |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| dynamic.cache.primer.limit              | CRConfig.json          | Limit the number of permutations to prime when dynamic zone cache priming is enabled; defaults to 500                                                                                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| keystore.maintenance.interval           | CRConfig.json          | The interval in seconds which Traffic Router will check the keystore API for new DNSSEC keys                                                                                                              |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| keystore.api.url                        | CRConfig.json          | The keystore API URL (https://${tmHostname}/api/1.1/cdns/name/${cdnName}/dnsseckeys.json; ${tmHostname} and ${cdnName} are search and replace tokens used by Traffic Router to construct the correct URL) |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| keystore.fetch.timeout                  | CRConfig.json          | The timeout in milliseconds for requests to the keystore API                                                                                                                                              |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| keystore.fetch.retries                  | CRConfig.json          | The number of times Traffic Router will attempt to load keys before giving up; defaults to 5                                                                                                              |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| keystore.fetch.wait                     | CRConfig.json          | The number of milliseconds Traffic Router will wait before a retry                                                                                                                                        |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| signaturemanager.expiration.multiplier  | CRConfig.json          | Multiplier used in conjunction with a zone's maximum TTL to calculate DNSSEC signature durations; defaults to 5                                                                                           |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| zonemanager.threadpool.scale            | CRConfig.json          | Multiplier used to determine the number of cores to use for zone signing operations; defaults to 0.75                                                                                                     |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| zonemanager.cache.maintenance.interval  | CRConfig.json          | The interval in seconds which Traffic Router will check for zones that need to be resigned or if dynamic zones need to be expired from cache                                                              |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| zonemanager.dynamic.response.expiration | CRConfig.json          | A string (e.g.: 300s) that defines how long a dynamic zone                                                                                                                                                |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DNSKEY.generation.multiplier            | CRConfig.json          | Used to deteremine when new keys need to be regenerated. Keys are regenerated if expiration is less than the generation multiplier * the TTL.  If the parameter does not exist, the default is 10.        |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| DNSKEY.effective.multiplier             | CRConfig.json          | Used when creating an effective date for a new key set.  New keys are generated with an effective date of old key expiration - (effective multiplier * TTL).  Default is 2.                               |
+-----------------------------------------+------------------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+


..   index::
  HOST_REGEXP
  PATH_REGEXP
  HEADER_REGEXP
  Delivery Service regexp

.. _rl-ds-regexp:

Delivery Service Regexp
+++++++++++++++++++++++
This table defines how requests are matched to the delivery service. There are 3 type of entries possible here:

+---------------+----------------------------------------------------------------------+--------------+-----------+
|      Name     |                             Description                              |   DS Type    |   Status  |
+===============+======================================================================+==============+===========+
| HOST_REGEXP   | This is the regular expresion to match the host part of the URL.     | DNS and HTTP | Supported |
+---------------+----------------------------------------------------------------------+--------------+-----------+
| PATH_REGEXP   | This is the regular expresion to match the path part of the URL.     | HTTP         | Beta      |
+---------------+----------------------------------------------------------------------+--------------+-----------+
| HEADER_REGEXP | This is the regular expresion to match on any header in the request. | HTTP         | Beta      |
+---------------+----------------------------------------------------------------------+--------------+-----------+

The **Order** entry defines the order in which the regular expressions get evaluated. To support ``CNAMES`` from domains outside of the Traffic Control top level DNS domain, enter multiple ``HOST_REGEXP`` lines.

Example:
  Example foo.

.. Note:: In most cases is is sufficient to have just one entry in this table that has a ``HOST_REGEXP`` Type, and Order ``0``. For the *movies* delivery service in the Kabletown CDN, the entry is simply single ``HOST_REGEXP`` set to ``.*\.movies\..*``. This will match every url that has a hostname that ends with ``movies.cdn1.kabletown.net``, since ``cdn1.kabletown.net`` is the Kabletown CDN's DNS domain.

.. index::
  Static DNS Entries

.. _rl-static-dns:

Static DNS Entries
++++++++++++++++++
Static DNS entries allow you to create other names *under* the delivery service domain. You can enter any valid hostname, and create a CNAME, A or AAAA record for it by clicking the **Static DNS** button at the bottom of the delivery service details screen.

.. index::
  Server Assignments

.. _rl-assign-edges:

Server Assignments
++++++++++++++++++
Click the **Server Assignments** button at the bottom of the screen to assign servers to this delivery service.  Servers can be selected by drilling down in a tree, starting at the profile, then the cache group, and then the individual servers. Traffic Router will only route traffic for this delivery service to servers that are assigned to it.


.. _rl-asn-czf:

The Coverage Zone File and ASN Table
++++++++++++++++++++++++++++++++++++
The Coverage Zone File (CZF) should contain a cachegroup name to network prefix mapping in the form: ::

  {
    "coverageZones": {
      "cache-group-01": {
        "network6": [
          "1234:5678::\/64",
          "1234:5679::\/64"
        ],
        "network": [
          "192.168.8.0\/24",
          "192.168.9.0\/24"
        ]
      }
      "cache-group-02": {
        "network6": [
          "1234:567a::\/64",
          "1234:567b::\/64"
        ],
        "network": [
          "192.168.4.0\/24",
          "192.168.5.0\/24"
        ]
      }
    }
  }

The CZF is an input to the Traffic Control CDN, and as such does not get generated by Traffic Ops, but rather, it gets consumed by Traffic Router. Some popular IP management systems output a very similar file to the CZF but in stead of a cachegroup an ASN will be listed. Traffic Ops has the "Networks (ASNs)" view to aid with the conversion of files like that to a Traffic Control CZF file; this table is not used anywhere in Traffic Ops, but can be used to script the conversion using the API.

The script that generates the CZF file is not part of Traffic Control, since it is different for each situation.

.. _rl-working-with-profiles:

Parameters and Profiles
=======================
Parameters are shared between profiles if the set of ``{ name, config_file, value }`` is the same. To change a value in one profile but not in others, the parameter has to be removed from the profile you want to change it in, and a new parameter entry has to be created (**Add Parameter** button at the bottom of the Parameters view), and assigned to that profile. It is easy to create new profiles from the **Misc > Profiles** view - just use the **Add/Copy Profile** button at the bottom of the profile view to copy an existing profile to a new one. Profiles can be exported from one system and imported to another using the profile view as well. It makes no sense for a parameter to not be assigned to a single profile - in that case it really has no function. To find parameters like that use the **Parameters > Orphaned Parameters** view. It is easy to create orphaned parameters by removing all profiles, or not assigning a profile directly after creating the parameter.

.. seealso:: :ref:`rl-param-prof` in the *Configuring Traffic Ops* section.



Tools
=====

.. index::
  ISO
  Generate ISO

.. _rl-generate-iso:

Generate ISO
++++++++++++

Generate ISO is a tool for building custom ISOs for building caches on remote hosts. Currently it only supports Centos 6, but if you're brave and pure of heart you MIGHT be able to get it to work with other unix-like OS's.

The interface is *mostly* self explainatory as it's got hints.

+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Field                         |  Explaination                                                                                                                   |
+===============================+=================================================================================================================================+
|Choose a server from list:     | This option gets all the server names currently in the Traffic Ops database and will autofill known values.                     |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| OS Version:                   | There needs to be an _osversions.cfg_ file in the ISO directory that maps the name of a directory to a name that shows up here. |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Hostname:                     | This is the FQDN of the server to be installed. It is required.                                                                 |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Root password:                | If you don't put anything here it will default to the salted MD5 of "Fred". Whatever put is MD5 hashed and writte to disk.      |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| DHCP:                         | if yes, other IP settings will be ignored                                                                                       |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| IP Address:                   | Required if DHCP=no                                                                                                             |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Netmask:                      | Required if DHCP=no                                                                                                             |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Gateway:                      | Required if DHCP=no                                                                                                             |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| IPV6 Address:                 | Optional. /64 is assumed if prefix is omitted                                                                                   |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| IPV6 Gateway:                 | Ignored if an IPV4 gateway is specified                                                                                         |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Network Device:               | Optional. Typical values are bond0, eth4, etc. Note: if you enter bond0, a LACP bonding config will be written                  |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| MTU:                          | If unsure, set to 1500                                                                                                          |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Specify disk for OS install:  | Optional. Typical values are "sda".                                                                                             |
+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------+


When you click the **Download ISO** button the folling occurs (all paths relative to the top level of the directory specified in _osversions.cfg_):

#. Reads /etc/resolv.conf to get a list of nameservers. This is a rather ugly hack that is in place until we get a way of configuring it in the interface.
#. Writes a file in the ks_scripts/state.out that contains directory from _osversions.cfg_ and the mkisofs string that we'll call later.
#. Writes a file in the ks_scripts/network.cfg that is a bunch of key=value pairs that set up networking.
#. Creates an MD5 hash of the password you specify and writes it to ks_scripts/password.cfg. Note that if you do not specify a password "Fred" is used. Also note that we have experienced some issues with webbrowsers autofilling that field.
#. Writes out a disk configuration file to ks_scripts/disk.cfg.
#. mkisofs is called against the directory configured in _osversions.cfg_ and an ISO is generated in memory and delivered to your webbrowser.

You now have a customized ISO that can be used to install Red Hat and derivative Linux installations with some modifications to your ks.cfg file.

Kickstart/Anaconda will mount the ISO at /mnt/stage2 during the install process (at least with 6).

You can directly include the password file anywhere in your ks.cfg file (usually in the top) by doing %include /mnt/stage2/ks_scripts/password.cfg

What we currently do is have 2 scripts, one to do hard drive configuration and one to do network configuration. Both are relatively specific to the environment they were created in, and both are *probably* wrong for other organizations, however they are currently living in the "misc" directory as examples of how to do things.

We trigger those in a %pre section in ks.cfg and they will write config files to /tmp. We will then include those files in the appropriate places using  %pre.

For example this is a section of our ks.cfg file: ::

  %include /mnt/stage2/ks_scripts/packages.txt

  %pre
    python /mnt/stage2/ks_scripts/create_network_line.py
    bash /mnt/stage2/ks_scripts/drive_config.sh
  %end

These two scripts will then run _before_ anaconda sets up it's internal structures, then a bit further up in the ks.cfg file (outside of the %pre %end block) we do an ::

    %include /mnt/stage2/ks_scripts/password.cfg
    ...
    %include /tmp/network_line

    %include /tmp/drive_config
    ...

This snarfs up the contents and inlines them.

If you only have one kind of hardware on your CDN it is probably best to just put the drive config right in the ks.cfg.

If you have simple networking needs (we use bonded interfaces in most, but not all locations and we have several types of hardware meaning different ethernet interface names at the OS level etc.) then something like this: ::

  #!/bin/bash
  source /mnt/stage2/ks_scripts/network.cfg
  echo "network --bootproto=static --activate --ipv6=$IPV6ADDR --ip=$IPADDR --netmask=$NETMASK --gateway=$GATEWAY --ipv6gateway=$GATEWAY --nameserver=$NAMESERVER --mtu=$MTU --hostname=$HOSTNAME" >> /tmp/network.cfg
  # Note that this is an example and may not work at all.


You could also put this in the %pre section. Lots of ways to solve it.

We have included the two scripts we use in the "misc" directory of the git repo:

* kickstart_create_network_line.py
* kickstart_drive_config.sh

These scripts were written to support a very narrow set of expectations and environment and are almost certainly not suitable to just drop in, but they might provide a good starting point.

.. _rl-queue-updates:

Queue Updates and Snapshot CRConfig
+++++++++++++++++++++++++++++++++++
When changing delivery services special care has to be taken so that Traffic Router will not send traffic to caches for delivery services that the cache doesn't know about yet. In general, when adding delivery services, or adding servers to a delivery service, it is best to update the caches before updating Traffic Router and Traffic Monitor. When deleting delivery services, or deleting server assignments to delivery services, it is best to update Traffic Router and Traffic Monitor first and then the caches. Updating the cache configuration is done through the *Queue Updates* menu, and updating Traffic Monitor and  Traffic Router config is done through the *Snapshot CRConfig* menu.

.. index::
  Cache Updates
  Queue Updates

Queue Updates
^^^^^^^^^^^^^
Every 15 minutes the caches will run a *syncds* to get all changes needed from Traffic Ops. The files that will be updated by the syncds job are:

- records.config
- remap.config
- parent.config
- cache.config
- hosting.config
- url\_sig\_(.*)\.config
- hdr\_rw\_(.*)\.config
- regex_revalidate.config
- ip_allow.config

A cache will only get updated when the update flag is set for it. To set the update flag, use the *Queue Updates* menu - here you can schedule updates for a whole CDN or a cache group:

  #. Click **Tools > Queue Updates**.
  #. Select the CDN to queueu uodates for, or All.
  #. Select the cache group to queue updates for, or All
  #. Click the **Queue Updates** button.
  #. When the Queue Updates for this Server? (all) window opens, click **OK**.

To schedule updates for just one cache, use the "Server Checks" page, and click the |checkmark| in the *UPD* column. The UPD column of Server Checks page will change show a |clock| when updates are pending for that cache.


.. index::
  Snapshot CRConfig

.. _rl-snapshot-crconfig:

Snapshot CRConfig
^^^^^^^^^^^^^^^^^

Every 60 seconds Traffic Monitor will check with Traffic Ops to see if a new CRConfig snapshot exists; Traffic Monitor polls Traffic Ops for a new CRConfig, and Traffic Router polls Traffic Monitor for the same file. This is necessary to ensure that Traffic Monitor sees configuration changes first, which helps to ensure that the health and state of caches and delivery services propagates properly to Traffic Router. See :ref:`rl-ccr-profile` for more information on the CRConfig file.

To create a new snapshot, use the *Tools > Snapshot CRConfig* menu:

  #. Click **Tools > Snapshot CRConfig**.
  #. Verify the selection of the correct CDN from the Choose CDN drop down and click **Diff CRConfig**.
     On initial selection of this, the CRConfig Diff window says the following:

     There is no existing CRConfig for [cdn] to diff against... Is this the first snapshot???
     If you are not sure why you are getting this message, please do not proceed!
     To proceed writing the snapshot anyway click the 'Write CRConfig' button below.

     If there is an older version of the CRConfig, a window will pop up showing the differences
     between the active CRConfig and the CRConfig about to be written.

  #. Click **Write CRConfig**.
  #. When the This will push out a new CRConfig.json. Are you sure? window opens, click **OK**.
  #. The Successfully wrote CRConfig.json! window opens, click **OK**.


.. index::
  Invalidate Content
  Purge

.. _rl-purge:

Invalidate Content
==================
Invalidating content on the CDN is sometimes necessary when the origin was mis-configured and something is cached in the CDN  that needs to be removed. Given the size of a typical Traffic Control CDN and the amount of content that can be cached in it, removing the content from all the caches may take a long time. To speed up content invalidation, Traffic Ops will not try to remove the content from the caches, but it makes the content inaccessible using the *regex_revalidate* ATS plugin. This forces a *revalidation* of the content, rather than a new get.

.. Note:: This method forces a HTTP *revalidation* of the content, and not a new *GET* - the origin needs to support revalidation according to the HTTP/1.1 specification, and send a ``200 OK`` or ``304 Not Modified`` as applicable.

To invalidate content:

  1. Click **Tools > Invalidate Content**
  2. Fill out the form fields:

    - Select the **Delivery Service**
    - Enter the **Path Regex** - this should be a `PCRE <http://www.pcre.org/>`_ compatible regular expression for the path to match for forcing the revalidation. Be careful to only match on the content you need to remove - revalidation is an expensive operation for many origins, and a simple ``/.*`` can cause an overload condition of the origin.
    - Enter the **Time To Live** - this is how long the revalidation rule will be active for. It usually makes sense to make this the same as the ``Cache-Control`` header from the origin which sets the object time to live in cache (by ``max-age`` or ``Expires``). Entering a longer TTL here will make the caches do unnecessary work.
    - Enter the **Start Time** - this is the start time when the revalidation rule will be made active. It is pre-populated with the current time, leave as is to schedule ASAP.

  3. Click the **Submit** button.


Manage DNSSEC Keys
====================

In order to support `DNSSEC <https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions>`_ in Traffic Router, Traffic Ops provides some actions for managing DNSSEC keys for a CDN and associated Delivery Services.  DNSSEC Keys consist of a Key Signing Keys (KSK) which are used to sign other DNSKEY records as well as Zone Signing Keys (ZSK) which are used to sign other records.  DNSSEC Keys are stored in `Traffic Vault <../overview/traffic_vault.html>`_ and should only be accessible to Traffic Ops.  Other applications needing access to this data, such as Traffic Router, must use the Traffic Ops `DNSSEC APIs <../development/traffic_ops_api/v12/cdn.html#dnssec-keys>`_ to retrieve this information.

To Manage DNSSEC Keys:
  1. Click **Tools -> Manage DNSSEC Keys**
  2. Choose a CDN and click **Manage DNSSEC Keys**

    - If keys have not yet been generated for a CDN, this screen will be mostly blank with just the **CDN** and **DNSSEC Active?** fields being populated.
    - If keys have been generated for the CDN, the Manage DNSSEC Keys screen will show the TTL and Top Level Domain (TLD) KSK Expiration for the CDN as well as DS Record information which will need to be added to the parent zone of the TLD in order for DNSSEC to work.

The Manage DNSSEC Keys screen also allows a user to perform the following actions:

**Activate/Deactivate DNSSEC for a CDN**

Fairly straight forward, this button set the **dnssec.enabled** param to either **true** or **false** on the Traffic Router profile for the CDN.  The Activate/Deactivate option is only available if DNSSEC keys exist for CDN.  In order to active DNSSEC for a CDN a user must first generate keys and then click the **Active DNSSEC** button.

**Generate Keys**

Generate Keys will generate dnssec keys for the CDN TLD as well as for each Delivery Service in the CDN.  It is important to note that this button will create a new KSK for the TLD and, therefore, a new DS Record.  Any time a new DS Record is created, it will need to be added to the parent zone of the TLD in order for DNSSEC to work properly.  When a user clicks the **Generate Keys** button, they will be presented with a screen with the following fields:

  - **CDN:** This is not editable and displays the CDN for which keys will be generated
  - **ZSK Expiration (Days):**  Sets how long (in days) the Zone Signing Key will be valid for the CDN and associated Delivery Services. The default is 30 days.
  - **KSK Expiration (Days):**  Sets how long (in days) the Key Signing Key will be valid for the CDN and associated Delivery Services. The default is 365 days.
  - **Effective Date (GMT):** The time from which the new keys will be active.  Traffic Router will use this value to determine when to start signing with the new keys and stop signing with the old keys.

Once these fields have been correctly entered, a user can click Generate Keys.  The user will be presented with a confirmation screen to help them understand the impact of generating the keys.  If a user confirms, the keys will be generated and stored in Traffic Vault.

**Regenerate KSK**

Regenerate KSK will create a new Key Signing Key for the CDN TLD. A new DS Record will also be generated and need to be put into the parent zone in order for DNSSEC to work correctly. The **Regenerate KSK** button is only available if keys have already been generated for a CDN.  The intent of the button is to provide a mechanism for generating a new KSK when a previous one expires or if necessary for other reasons such as a security breach.  When a user goes to generate a new KSK they are presented with a screen with the following options:

  - **CDN:** This is not editable and displays the CDN for which keys will be generated
  - **KSK Expiration (Days):**  Sets how long (in days) the Key Signing Key will be valid for the CDN and associated Delivery Services. The default is 365 days.
  - **Effective Date (GMT):** The time from which the new KSK and DS Record will be active.  Since generating a new KSK will generate a new DS Record that needs to be added to the parent zone, it is very important to make sure that an effective date is chosen that allows for time to get the DS Record into the parent zone.  Failure to get the new DS Record into the parent zone in time could result in DNSSEC errors when Traffic Router tries to sign responses.

Once these fields have been correctly entered, a user can click Generate KSK.  The user will be presented with a confirmation screen to help them understand the impact of generating the KSK.  If a user confirms, the KSK will be generated and stored in Traffic Vault.

Additionally, Traffic Ops also performs some systematic management of DNSSEC keys.  This management is necessary to help keep keys in sync for Delivery Services in a CDN as well as to make sure keys do not expire without human intervention.

**Generation of keys for new Delivery Services**

If a new Delivery Service is created and added to a CDN that has DNSSEC enabled, Traffic Ops will create DNSSEC keys for the Delivery Service and store them in Traffic Vault.

**Regeneration of expiring keys for a Delivery Service**

Traffic Ops has a process, controlled by cron, to check for expired or expiring keys and re-generate them.  The process runs at 5 minute intervals to check and see if keys are expired or close to expiring (withing 10 minutes by default).  If keys are expired for a Delivery Service, traffic ops will regenerate new keys and store them in Traffic Vault.  This process is the same for the CDN TLD ZSK, however Traffic Ops will not re-generate the CDN TLD KSK systematically.  The reason is that when a KSK is regenerated for the CDN TLD then a new DS Record will also be created.  The new DS Record needs to be added to the parent zone before Traffic Router attempts to sign with the new KSK in order for DNSSEC to work correctly.  Therefore, management of the KSK needs to be a manual process.





