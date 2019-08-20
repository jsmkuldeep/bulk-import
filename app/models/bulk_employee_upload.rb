class BulkEmployeeUpload < ApplicationRecord
    mount_uploader :file, BulkEmployeeFileUploader
    belongs_to :company
    validates_with EmployeeCsvValidator

    after_create :start_create_employee_job

    def start_create_employee_job
        CreateEmployeeJob.perform_later(self)
    end

    def to_csv
        require 'csv'
        CSV.generate(headers: true) do |csv|
            attributes = ["Employee Name", "Email", "Phone", "Report To", "Assigned Policies"]
            upload_errors = EmpTempStorageError.where(bulk_employee_upload_id: self.id).map{|i| JSON.parse(i.data).with_indifferent_access }
            csv << attributes
            upload_errors.each do |car|
                csv << attributes.map{|i| i.parameterize.underscore}.map{ |attr| car[attr] }
            end
        end
    end
end
