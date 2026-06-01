# frozen_string_literal: true

class BackfillReceiptReportOptionDefault < ActiveRecord::Migration[7.0]
  # The original migration (20230513033336) set the column default to 0 ("none"),
  # but the WeeklyJob previously iterated User.all, so the column value was
  # never checked. Now that each cadence job filters by the user's preference,
  # we need to backfill existing users to 1 ("weekly") so they keep receiving
  # the reports they were already getting. We also fix the column default so
  # new users start on "weekly" at the DB level too.
  def up
    # Preserve existing behavior: users who were getting weekly emails (everyone)
    # should continue to get them.
    User.where(receipt_report_option: 0).update_all(receipt_report_option: 1)

    change_column_default :users, :receipt_report_option, from: 0, to: 1
  end

  def down
    change_column_default :users, :receipt_report_option, from: 1, to: 0
  end
end
