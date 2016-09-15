/*
    Copyright 2016 Comcast Cable Communications Management, LLC

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied

-- steering_target
CREATE TABLE if not exists `steering_target` (
  `deliveryservice` INT(11) NOT NULL,
  `target` INT(11) NOT NULL,
  `weight` int(11) NOT NULL,
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`deliveryservice`, `target`),
  CONSTRAINT `fk_steering_target_delivery_service` FOREIGN KEY (`deliveryservice`) REFERENCES `deliveryservice` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_steering_target_target` FOREIGN KEY (`deliveryservice`) REFERENCES `deliveryservice` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT IGNORE INTO role (name, description, priv_level) values ('steering', 'Role for Steering Delivery Services', 15);
INSERT IGNORE INTO type (name, description, use_in_table) values ('STEERING', 'Steering Delivery Service', 'deliveryservice');
INSERT IGNORE INTO type (name, description, use_in_table) values ('STEERING_REGEXP', 'Steering target filter regular expression', 'regex');

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
