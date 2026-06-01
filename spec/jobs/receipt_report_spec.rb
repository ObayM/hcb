# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ReceiptReport Jobs" do
  include ActiveJob::TestHelper

  let!(:user_none) { create(:user, receipt_report_option: :none) }
  let!(:user_daily) { create(:user, receipt_report_option: :daily) }
  let!(:user_weekly) { create(:user, receipt_report_option: :weekly) }
  let!(:user_monthly) { create(:user, receipt_report_option: :monthly) }

  before do
    allow_any_instance_of(User).to receive(:hcb_code_ids_missing_receipt).and_return([1])
  end

  describe ReceiptReport::DailyJob do
    it "only enqueues SendJob for daily users" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(ReceiptReport::SendJob).with(user_daily.id).once

      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_none.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_weekly.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_monthly.id)
    end
  end

  describe ReceiptReport::WeeklyJob do
    it "only enqueues SendJob for weekly users" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(ReceiptReport::SendJob).with(user_weekly.id).once

      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_none.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_daily.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_monthly.id)
    end
  end

  describe ReceiptReport::MonthlyJob do
    it "only enqueues SendJob for monthly users" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(ReceiptReport::SendJob).with(user_monthly.id).once

      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_none.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_daily.id)
      expect(ReceiptReport::SendJob).not_to have_been_enqueued.with(user_weekly.id)
    end
  end

  describe ReceiptReport::SendJob do
    it "sends mail with correct subject prefix" do
      mail = ReceiptableMailer.with(user_id: user_daily.id, hcb_ids: [1]).receipt_report
      expect(mail.subject).to include("[DAILY]")

      mail = ReceiptableMailer.with(user_id: user_weekly.id, hcb_ids: [1]).receipt_report
      expect(mail.subject).to include("[WEEKLY]")

      mail = ReceiptableMailer.with(user_id: user_monthly.id, hcb_ids: [1]).receipt_report
      expect(mail.subject).to include("[MONTHLY]")

      mail = ReceiptableMailer.with(user_id: user_none.id, hcb_ids: [1]).receipt_report
      expect(mail.subject).to include("[WEEKLY]")
    end
  end
end
