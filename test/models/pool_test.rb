#
# Copyright 2013 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class PoolTest < MiniTest::Rails::ActiveSupport::TestCase

  def self.before_suite
    #services = ["Candlepin", "Pulp", "ElasticSearch"]
    #disable_glue_layers(services, models)
  end

  def test_all_active_subscriptions
    active_pool = FactoryGirl.build(:pool, :active)
    inactive_pool = FactoryGirl.build(:pool, :inactive)
    all_subscriptions = [active_pool, inactive_pool]
    active_subscriptions = Pool.all_active(all_subscriptions)
    assert_equal active_subscriptions, all_subscriptions - inactive_pool
  end
end

