class CreateRackCasProxyGrantingTicketIous < ActiveRecord::Migration
  def self.up
    create_table :proxy_granting_ticket_ious do |t|
      t.string :proxy_granting_ticket_iou, :null => false
      t.string :proxy_granting_ticket, :null => false
      t.timestamps
    end

    add_index :proxy_granting_ticket_ious, :proxy_granting_ticket_iou
    add_index :proxy_granting_ticket_ious, :proxy_granting_ticket
    add_index :proxy_granting_ticket_ious, :updated_at
  end

  def self.down
    drop_table :proxy_granting_ticket_ious
  end
end