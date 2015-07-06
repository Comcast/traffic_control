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

.. index::
	Traffic Ops - Overview

.. |arrow| image:: fwda.png

Traffic Ops
===========
Traffic Ops is the tool for administration (configuration and monitoring) of all components in a Traffic Control CDN. The CDN administrator uses Traffic Ops to manage servers, cache groups, delivery services, etc. In many cases, a configuration change requires propagation to several, or even all, caches and only explicitly after or before the same change propagates to Traffic Router. Traffic Ops takes care of this required consistency between the different components and their configuration. Traffic Ops exposes its data through a series of HTTP APIs and has a user interface that is interactive and viewable using a standard web browser. 

Traffic Ops uses a MySQL or PostgreSQL database to store the configuration information, and the `Mojolicious framework <http://mojolicio.us/>`_ to generate the user interface and APIs. Not all configuration data is in the database, for sensitive data, like SSL private keys or token based authentication shared secrets, as a separate key value store is for use in allowing the operator to harden that server better from a security perspective (i.e only allow Traffic Ops access with a cert). The Traffic Ops server, by design, needs to be accessible from all the other servers in the Traffic Control CDN. 

Traffic Ops generates all the application specific configuration files for the caches and other servers. The caches and other servers check in with Traffic Ops at a regular interval (default 15 minutes) to see if updated configuration files require application. 

Traffic Ops also runs a collection of periodic checks to determine the operational readiness of the caches. These periodic checks are customizable by the Traffic Ops admin using extensions.

|

.. index::
	Traffic Ops Extensions - Overview
	
|arrow| Traffic Ops Extension
-----------------------------
  Traffic Ops Extensions are a way to enhance the basic functionality of Traffic Ops in a custom manner. There are three types of extensions:

  * Check Extensions - Allows you to add custom checks to the "Health->Server Checks" view.
  * Configuration Extension - Allows you to add custom configuration file generators.
  * Data source Extensions - Allows you to add data sources for the graph views and usage APIs.

