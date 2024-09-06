public class ContactManager {

    // Method to create a new Contact
    public static Contact createContact(String firstName, String lastName, String email) {
        Contact newContact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email
        );

        try {
            insert newContact;
            System.debug('Contact created with Id: ' + newContact.Id);
        } catch (DmlException e) {
            System.debug('Error creating contact: ' + e.getMessage());
            throw e;
        }
        
        return newContact;
    }

    // Method to update a Contact's email
    public static void updateContactEmail(Id contactId, String newEmail) {
        Contact existingContact = [SELECT Id, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        existingContact.Email = newEmail;

        try {
            update existingContact;
            System.debug('Contact updated with new email: ' + newEmail);
        } catch (DmlException e) {
            System.debug('Error updating contact: ' + e.getMessage());
            throw e;
        }
    }

    // Method to delete a Contact by Id
    public static void deleteContact(Id contactId) {
        Contact contactToDelete = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];

        try {
            delete contactToDelete;
            System.debug('Contact deleted with Id: ' + contactId);
        } catch (DmlException e) {
            System.debug('Error deleting contact: ' + e.getMessage());
            throw e;
        }
    }

    // Method to query Contacts by last name
    public static List<Contact> getContactsByLastName(String lastName) {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE LastName = :lastName];

        System.debug('Number of contacts found: ' + contacts.size());
        return contacts;
    }

    // Method to get a Contact by Id
    public static Contact getContactById(Id contactId) {
        Contact contact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        return contact;
    }
}