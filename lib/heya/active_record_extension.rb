# frozen_string_literal: true

require "active_record/relation"

module Heya
  module ActiveRecordRelationExtension
    TABLE_REGEXP = /heya_steps/

    def build_arel(aliases)
      arel = super(aliases)

      if table_name == "heya_campaign_memberships" && arel.to_sql =~ TABLE_REGEXP
        # https://www.postgresql.org/docs/9.4/queries-values.html
        values = Heya
          .campaigns.reduce([]) { |steps, campaign| steps | campaign.steps }
          .map { |step|
            ActiveRecord::Base.sanitize_sql_array(
              ["(?, ?)", step.gid, step.wait.to_i]
            )
          }

        if values.any?
          arel.with(
            Arel::Nodes::SqlLiteral.new(
              "heya_steps AS (SELECT * FROM (VALUES #{values.join(", ")}) AS heya_steps (gid,wait))"
            )
          )
        end
      end

      arel
    end
  end

  ActiveRecord::Relation.prepend(ActiveRecordRelationExtension)
end
