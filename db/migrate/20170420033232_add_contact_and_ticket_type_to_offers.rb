class AddContactAndTicketTypeToOffers < ActiveRecord::Migration[5.0]
  def change
    add_column(:offers, :contact, :string)
    add_column(:offers, :ticket_type, :string)
  end
end
