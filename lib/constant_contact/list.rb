module ConstantContact
  class List < Base

    # @@column_names = [:contact_count, :display_on_signup, :members, :name, :opt_in_default, :short_name, :sort_order]

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.tag!("ContactList", :xmlns => "http://ws.constantcontact.com/ns/1.0/") do
        self.attributes.each{|k, v| xml.tag!( k.to_s.camelize, v )}
      end
    end

    def self.find_by_name(name)
      lists = self.find :all
      lists.find{|list| list.Name == name}
    end


    def self.subscribe(params = [])
      id = params[:id].to_i || 1
      email = params[:email]
      contact = ConstantContact::Contact.new(email_address: email)
      begin
        contact.save
        contact.contact_lists = [id]
      rescue ActiveResource::ResourceConflict
        # Contact already exists, get the contact from CC
        # so we can add/update their contact lists.
        #
        # Unfortunately, it seems the only way to get all
        # of the contact's attributes, including contact lists
        # is to "find by id" - which we don't have yet, so
        # this requires 2 calls.
        contact = ConstantContact::Contact.find_by_email(email)
        contact = ConstantContact::Contact.find(contact.id)
        contact.contact_lists ||= []
        contact.contact_lists << id unless contact.contact_lists.include?(id)
      end
      # Now save to update the subscriber contact lists.
      contact.save

      contact
    end
  end
end
