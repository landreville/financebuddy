class ImportProfile < ApplicationRecord
  FILE_FORMATS = %w[ofx csv].freeze
  AMOUNT_STYLES = %w[signed negated separate_columns indicator_column].freeze

  belongs_to :ledger
  belongs_to :account

  validates :name, presence: true
  validates :file_format, presence: true, inclusion: { in: FILE_FORMATS }
  validates :amount_style, inclusion: { in: AMOUNT_STYLES }, allow_nil: true
end
