# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


require_relative '../spec_helper'

module Selenium
  module WebDriver
    class BiDi
      describe Network, exclusive: {bidi: true, reason: 'only executed when bidi is enabled'},
                        only: {browser: %i[chrome edge firefox]} do
        it 'adds an intercept' do
          reset_driver!(web_socket_url: true) do |driver|
            network = described_class.new(driver.bidi)
            intercept = network.add_intercept(phases: [described_class::PHASES[:before_request]])
            expect(intercept).not_to be_nil
          end
        end

        it 'removes an intercept' do
          reset_driver!(web_socket_url: true) do |driver|
            network = described_class.new(driver.bidi)
            intercept = network.add_intercept(phases: [described_class::PHASES[:before_request]])
            expect(network.remove_intercept(intercept['intercept'])).to be_empty
          end
        end

        it 'continues with auth' do
          username = SpecSupport::RackServer::TestApp::BASIC_AUTH_CREDENTIALS.first
          password = SpecSupport::RackServer::TestApp::BASIC_AUTH_CREDENTIALS.last
          reset_driver!(web_socket_url: true) do |driver|
            network = described_class.new(driver.bidi)
            network.add_intercept(phases: [described_class::PHASES[:auth_required]])
            network.on(:auth_required) do |event|
              request_id = event['requestId']
              network.continue_with_auth(request_id, username, password)
            end

            driver.navigate.to url_for('basicAuth')
            expect(driver.find_element(tag_name: 'h1').text).to eq('authorized')
          end
        end

        it 'continues with request' do
          reset_driver!(web_socket_url: true) do |driver|
            network = described_class.new(driver.bidi)
            network.add_intercept(phases: [described_class::PHASES[:before_request]])
            network.on(:before_request) do |event|
              request_id = event['requestId']
              network.continue_with_request(request_id: request_id)
            end

            driver.navigate.to url_for('formPage.html')
            expect(driver.find_element(name: 'login')).to be_displayed
          end
        end
      end
    end
  end
end
