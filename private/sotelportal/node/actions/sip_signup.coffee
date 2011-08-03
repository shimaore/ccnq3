# TODO Refactor using sammy.form.js and sammy.form_2_json.js

client sip_signup: ->

        $('#content').load '/p/sip_signup.html', ->

          options =
            buttons:
              'Correct': ->
                $(@).dialog 'close'
              'Submit anyway': ->
                ajaxSubmit false, ->
                  window.location = '.'
            closeOnEscape: true
            draggable: true
            modal: true
            title: 'Errors in form'

          $('#confirm_invalid').dialog(options).dialog('close')

          ajaxSubmit = (was_validated)->
            console.log "Submitting with was_validated = #{was_validated}"

          $('form.validate').validate

            debug: true

            submitHandler: (form)->
              $(form).each ->
                ajaxSubmit true

            invalidHandler: (form)->
              console.log 'invalidHandler'

              $('#confirm_invalid').dialog('open')

          # Form interaction

          # -- Billing method --
          update_billing_method = ->
            value = $('[name="billing_method.billing_method"]').val()
            console.log "Value is #{value}"
            for name in ['card','ach','account']
              if name is value
                $("#payment_information_#{name}").show()
              else
                $("#payment_information_#{name}").hide()


          $('[name="billing_method.billing_method"]').change update_billing_method
          update_billing_method()

          # -- auto_add --
          auto_add = (table) ->
            # First hide the template lines and add a "delete" button
            $('.template',table)
              .hide()
              .append '<td><div class="del ui-icon ui-icon-closethick">remove</div></td>'

            # This function adds a line to an existing table.
            add_line = ->

              # Count the number of data lines
              rank = 0
              $('tr.data',table).each -> rank++

              # Create a new row from the template
              row = $('.template',table)
                .clone()
                .removeClass('template')
                .addClass('data')
                .show()
                .appendTo(table)

              $('input,select',row).each ->
                $(@).attr 'name', (index,name)->
                  return name.replace '*', rank

              # Make the button active
              $('.del',row).click ->
                row.remove()
                return false

              return

            $('tr:first',table)
              .append '<th><div class="add ui-icon ui-icon-plusthick">add line</div></th>'
            $('.add',table)
              .click -> add_line()

            # Start by inserting one row.
            add_line()

          $('.auto_add').each (index,table) -> auto_add(table)

          $('#wizard').smartWizard({})
          
get '/sip_signup.html': ->
  partial 'sip_signup'

view sip_signup: ->

  div id:'confirm_invalid', ->
    p -> 'The form contains errors.'

  form method:'post', class:'validate', ->

    div id:"wizard", class:"swMain", ->
      ul ->
        li a href:'#step-0', ->
          label class:'stepNumber', -> 0
          span class:'stepDesc', -> 'Introduction<br/><small></small>'
        li a href:'#step-1', ->
          label class:'stepNumber', -> 1
          span class:'stepDesc', -> 'Step 1<br/><small>Physical Location</small>'
        li a href:'#step-2', ->
          label class:'stepNumber', -> 2
          span class:'stepDesc', -> 'Step 2<br/><small>Choose and Customize Services</small>'
        li a href:'#step-3', ->
          label class:'stepNumber', -> 3
          span class:'stepDesc', -> 'Step 3<br/><small>Billing Information</small>'
        li a href:'#step-4', ->
          label class:'stepNumber', -> 4
          span class:'stepDesc', -> 'Step 4<br/><small>Existing Service Information</small>'
        li a href:'#step-5', ->
          label class:'stepNumber', -> 5
          span class:'stepDesc', -> 'Step 5<br/><small>Technical Contact</small>'
        li a href:'#step-6', ->
          label class:'stepNumber', -> 6
          span class:'stepDesc', -> 'Step 6<br/><small>Terms, Conditions, and Signatures</small>'
        li a href:'#step-7', ->
          label class:'stepNumber', -> 7
          span class:'stepDesc', -> 'Step 7<br/><small>Confirmation</small>'

      div id:'step-0', ->
        h2 class:'stepTitle', -> 'Introduction'

        p -> 'This formulaire is to be used by Sotel Agent to signup a new SIP Services Customer.'

        p -> "What you'll need: ..."


        p -> '''
             Until we have our automated agent registration system, please enter your (agent's) own contact information below:
             (TODO this will get pre-populated in future versions)
             '''

        div id:'loa', class:'form', ->

          p  class:'normal', -> 'Letter of Agency'

          label  for:'loa.customer_name', class:'normal', -> 'Customer Name'
          input name:'loa.customer_name', class:'required minlength(2)'

          label  for:'loa.agent.company', class:'normal', -> 'Agent Company'
          input name:'loa.agent.company', class:'required minlength(2)'

          label  for:'loa.agent.contact_name', class:'normal', -> 'Agent Name'
          input name:'loa.agent.contact_name', class:'required minlength(2)'

          label  for:'loa.agent.address_1', class:'normal', -> 'Address'
          input name:'loa.agent.address_1', class:'required minlength(2)'

          label  for:'loa.agent.address_2', class:'normal', -> 'Address (line 2)'
          input name:'loa.agent.address_2', class:' minlength(2)'

          label  for:'loa.agent.city', class:'normal', -> 'City'
          input name:'loa.agent.city', class:'required minlength(2)'

          label  for:'loa.agent.state', class:'normal', -> 'State'
          input name:'loa.agent.state', class:'required minlength(2)'

          label  for:'loa.agent.postal_code', class:'normal', -> 'ZIP Code'
          input name:'loa.agent.postal_code', class:'required minlength(2)'

      div id:'step-1', ->
        h2 class:'stepTitle', -> 'Physical Location'

        div id:'physical_location',  class:'form', ->

          p -> 'Physical service address (used for 911). If the customer is moving, this must be their new service address.'

          label  for:'physical_location.company', class:'normal', -> 'Company'
          input name:'physical_location.company', class:'required text minlength(2)'

          label  for:'physical_location.address_1', class:'normal',  class:'normal', -> 'Address'
          input name:'physical_location.address_1', class:'required text minlength(2)'

          label  for:'physical_location.address_2', class:'normal', -> 'Address (line 2)'
          input name:'physical_location.address_2', class:'text minlength(2)'

          label  for:'physical_location.city', class:'normal', -> 'City'
          input name:'physical_location.city', class:'required text minlength(2)'

          label  for:'physical_location.state', class:'normal', -> 'State'
          input name:'physical_location.state', class:'required text minlength(2)'

          label  for:'physical_location.postal_code', class:'normal', -> 'ZIP Code'
          input name:'physical_location.postal_code', class:'required digits minlength(2)'

          label  for:'physical_location.county', class:'normal', -> 'County'
          input name:'physical_location.county', class:'required text minlength(2)'

          div id:'physical_location_contact',  class:'form', ->

            label  for:'physical_location.contact.name', class:'normal', -> 'Contact Name'
            input name:'physical_location.contact.name', class:'required name minlength(2)'

            label  for:'physical_location.contact.phone', class:'normal', -> 'Contact Telephone'
            input name:'physical_location.contact.phone', class:'required phoneUS minlength(2)'

            label  for:'physical_location.contact.email', class:'normal', -> 'Contact Email'
            input name:'physical_location.contact.email', class:'required email minlength(2)'

      div id:'step-2', ->
        h2 class:'stepTitle', -> 'Choose and Customize Services'

        div class:'form', ->

          label  for:'service_information.services_requested', class:'normal', -> 'Services Requested'
          input name:'service_information.services_requested', class:'required minlength(2)'

          label  for:'service_information.services_term', class:'normal', -> 'Services Terms'
          select name:'service_information.services_term', class:'required number',  class:'normal', ->
            option value:12,  class:'normal', -> '12 months'
            option value:24,  class:'normal', -> '24 months'
            option value:36,  class:'normal', -> '36 months'

          label  for:'service_information.plan', class:'normal', -> 'Plan'
          input name:'service_information.plan', class:'required minlength(2)'

        div id:'setup_price_elements', class:'form', ->

          p  class:'normal', -> 'SETUP PRICE ELEMENTS (Non recurring charges)'

          div id:'setup_price_elements_voice_service_setup', class:'form', ->

            label  for:'setup_price_elements.voice_service_setup.ref', class:'normal', -> 'Voice Services Setup'
            input name:'setup_price_elements.voice_service_setup.ref', class:'required minlength(2)'

            label  for:'setup_price_elements.voice_service_setup.qty', class:'normal', -> 'Qty'
            input name:'setup_price_elements.voice_service_setup.qty', class:'required minlength(2)'

          label  for:'setup_price_elements.data_service_setup', class:'normal', -> 'Data Services Setup: Custom Quotation Required'
          input name:'setup_price_elements.data_service_setup', class:'required minlength(2)'

          label  for:'setup_price_elements.did_port_optiflex', class:'normal', -> 'DID Port (Opti-Flex)'
          input name:'setup_price_elements.did_port_optiflex', class:'required minlength(2)'

          label  for:'setup_price_elements.install_charge_optimax', class:'normal', -> 'Install Charge (Opti-Max)'
          input name:'setup_price_elements.install_charge_optimax', class:'required minlength(2)'

          label  for:'setup_price_elements.tollfree_number_port', class:'normal', -> 'Toll-Free Number Port'
          input name:'setup_price_elements.tollfree_number_port', class:'required minlength(2)'

          label  for:'setup_price_elements.pri_gateway_purchase', class:'normal', -> 'PRI Gateway Purchase'
          input name:'setup_price_elements.pri_gateway_purchase', class:'required minlength(2)'

          p  class:'normal', -> '2-port Analog Gateway Purchase'

        div id:'voice_services_plan', class:'form', ->
          label for:'voice_services_plan',  class:'normal', -> 'VOICE SERVICES PLANS (Monthly Recurring charges)'

          select name:'voice_services_plan',  class:'normal', ->
            option value:'optiflex', class:'normal', -> 'Opti-Flex IP (per US DID)'
            option value:'optimax', class:'normal', -> 'Opti-Max IP (unlimited usage)'

          div id:'', class:'form', -> 'International DID'

          div id:'service_plan', class:'form', -> 'SERVICE PLAN OPTIONS (Recurring charges)'

          div id:'', class:'form', -> 'Opti-Flex IP (per US DID)'

          div id:'', class:'form', -> 'US Toll-Free Number'

          div id:'broadband_service', class:'form', ->
            p  class:'normal', -> 'BROADBAND ACCESS AND DATA SERVICES (Recurring charges)'

            p  class:'normal', -> 'All Broadband Access and Data Services require a custom quote for charges based on the physical address of the installation.'

            label  for:'broadband_service.connectivity', class:'normal', -> 'Connectivity'
            input name:'broadband_service.connectivity', class:'required minlength(2)'

            label  for:'broadband_service.term', class:'normal', -> 'Term'
            input name:'broadband_service.term', class:'required minlength(2)'

            label  for:'broadband_service.charge', class:'normal', -> 'Charge'
            input name:'broadband_service.charge', class:'required minlength(2)'

            label  for:'broadband_service.qty', class:'normal', -> 'Qty'
            input name:'broadband_service.qty', class:'required minlength(2)'

          div id:'additional_reqs', class:'form', -> 'ADDITONAL REQUIREMENTS AND SPECIAL REQUESTS'

        div id:'new_did', class:'form', ->

          p  class:'normal', -> 'New DIDs Order (do not include any number you are porting from your existing provider)'

          label  for:'setup_price_elements.fax_needed', class:'normal', -> 'MANDATORY - If ordering new DID, please specify if: Inbound/Outbound faxing needed?'
          input name:'setup_price_elements.fax_needed', class:'required minlength(2)'

          div id:'new_did_numbers', class:'form auto_add', ->
            label  for:'new_did.numbers[*].count',  class:'normal', -> 'Quantity'
            input name:'new_did.numbers[*].count', class: 'required numeric'

            label  for:'new_did.numbers[*].state',  class:'normal', -> 'State'
            input name:'new_did.numbers[*].state', class: 'required minlength(2)'

            label  for:'new_did.numbers[*].ratecenter',  class:'normal', -> 'Ratecenter'
            input name:'new_did.numbers[*].ratecenter', class: 'required minlength(4)'


        div id:'new_tf', class:'form', ->

          p  class:'normal', -> 'New Toll-Free Numbers Ordering (do not include any number you might be porting from your existing carrier)'

          label  for:'new_tf.count',  class:'normal', ->'Number of new toll-free numbers needed'
          input name:'new_tf.count', class:'required numeric'

          div id:'new_tf_numbers', class:'form auto_add', ->

            label  for:'new_tf.numbers[*].coverage_usa', class:'normal', -> 'USA'
            input type:'checkbox', name:'tf.numbers[*].coverage_usa', value:true

            label  for:'new_tf.numbers[*].coverage_canada', class:'normal', -> 'Canada'
            input type:'checkbox', name:'tf.numbers[*].coverage_canada', value:true

            label  for:'new_tf.numbers[*].coverage_caribbean', class:'normal', -> 'Carribean'
            input type:'checkbox', name:'tf.numbers[*].coverage_caribbean', value:true

            label  for:'new_tf.numbers[*].fax_needed', class:'normal', -> 'Fax needed'
            input type:'checkbox', name:'tf.numbers[*].coverage_caribbean', value:true

            label  for:'tf.numbers[*].number', class:'normal', -> 'Vanity Number: if desired, enter a number or part of the number'
            input name:'tf.numbers[*].number', class:''

      div id:'step-4', ->
        h2 class:'stepTitle', -> 'Existing Services'

        div id:'lnp', class:'form', ->

          p  class:'normal', -> 'Local Numbers Portability'

          label  for:'lnp.company', class:'normal', -> 'End-user business name'
          input name:'lnp.company', class:'required minlength(2)'

          label  for:'lnp.name', class:'normal', -> 'Person authorized'
          input name:'lnp.name', class:'required minlength(2)'

          div id:'lnp_service_address_on_bill', class:'form', ->

            p  class:'normal', -> 'Service Address as it appears on bill'

            label  for:'lnp.service_address_on_bill.customer_name', class:'normal', -> 'Customer name (as it appears on bill)'
            input name:'lnp.service_address_on_bill.customer_name', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.address_1', class:'normal', -> 'Address'
            input name:'lnp.service_address_on_bill.address_1', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.address_2', class:'normal', -> 'Address (Suite, Appartment, ..)'
            input name:'lnp.service_address_on_bill.address_2', class:' minlength(2)'

            label  for:'lnp.service_address_on_bill.city', class:'normal', -> 'City'
            input name:'lnp.service_address_on_bill.city', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.state', class:'normal', -> 'State'
            input name:'lnp.service_address_on_bill.state', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.postal_code', class:'normal', -> 'ZIP Code'
            input name:'lnp.service_address_on_bill.postal_code', class:'required minlength(5)'

            label  for:'lnp.service_address_on_bill.contact_name', class:'normal', -> 'Contact Name'
            input name:'lnp.service_address_on_bill.contact_name', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.phone', class:'normal', -> 'Telephone'
            input name:'lnp.service_address_on_bill.phone', class:'required minlength(2)'

            label  for:'lnp.service_address_on_bill.billing_account_number', class:'normal', -> 'Billing Account Number'
            input name:'lnp.service_address_on_bill.billing_account_number', class:'required minlength(2)'

          table id:'lnp_numbers',  class:'form auto_add', ->

            tr ->
              th -> 'Beginning Range TN'
              th -> 'End Range TN'
              th -> 'Billing TN (main number)'
              th -> 'Fax needed'

            tr class:'template', ->
              td -> input name:'lnp.numbers[*].beginning', class:'required minlength(2)'
              td -> input name:'lnp.numbers[*].end', class:'required minlength(2)'
              td -> input name:'lnp.numbers[*].btn', class:'required minlength(2)'
              td -> input type:'checkbox', name:'lnp.numbers[*].fax_needed', value:true

          label  for:'lnp.requested_provisioning_date', class:'normal', -> 'Requested Provisioning Date'
          input name:'lnp.requested_provisioning_date', class:'required minlength(2)'

        div id:'tf', class:'form', ->

          p  class:'normal', -> 'Toll-Free Porting -- Responsible Organization Letter of Authorization'

          label  for:'tf.current_carrier', class:'normal', -> 'Current Carrier'
          input name:'tf.current_carrier', class:'required minlength(2)'

          label  for:'tf.requested_provisioning_date', class:'normal', -> 'Delivery Date'
          input name:'tf.requested_provisioning_date', class:'required minlength(2)'

          div id:'tf_numbers', class:'form auto_add', ->

            label  for:'tf.numbers[*].number', class:'normal', -> 'Number'
            input name:'tf.numbers[*].number', class:'required numeric minlength(10)'

            label  for:'tf.numbers[*].coverage_usa', class:'normal', -> 'USA'
            input type:'checkbox', name:'tf.numbers[*].coverage_usa', value:true

            label  for:'tf.numbers[*].coverage_canada', class:'normal', -> 'Canada'
            input type:'checkbox', name:'tf.numbers[*].coverage_canada', value:true

            label  for:'tf.numbers[*].coverage_caribbean', class:'normal', -> 'Caribbean'
            input type:'checkbox', name:'tf.numbers[*].coverage_caribbean', value:true

            label  for:'tf.numbers[*].fax_needed', class:'normal', -> 'Fax needed'
            input type:'checkbox', name:'tf.numbers[*].coverage_caribbean', value:true


      div id:'step-3', ->
        h2 class:'stepTitle', -> 'Billing Information'


        div id:'billing_location', class:'form', ->

          p  class:'normal', -> 'Billing Address. If the customer is moving, this must be their new billing address.'

          label  for:'billing_location.company', class:'normal', -> 'Company'
          input name:'billing_location.company', class:'required minlength(2)'

          label  for:'billing_location.address_1', class:'normal', -> 'Address'
          input name:'billing_location.address_1', class:'required minlength(2)'

          label  for:'billing_location.address_2', class:'normal', -> 'Address (line 2)'
          input name:'billing_location.address_2', class:' minlength(2)'

          label  for:'billing_location.city', class:'normal', -> 'City'
          input name:'billing_location.city', class:'required minlength(2)'

          label  for:'billing_location.state', class:'normal', -> 'State'
          input name:'billing_location.state', class:'required minlength(2)'

          label  for:'billing_location.postal_code', class:'normal', -> 'Zip Code'
          input name:'billing_location.postal_code', class:'required minlength(5)'

          label  for:'billing_location.county', class:'normal', -> 'County'
          input name:'billing_location.county', class:'required minlength(2)'

          div id:'billing_information_tax_exempt', class:'form', ->

            label  for:'billing_information.tax_exempt.federal', class:'normal', -> 'Tax Exempt: Federal'
            input name:'billing_information.tax_exempt.federal', class:'required minlength(2)'

            label  for:'billing_information.tax_exempt.state', class:'normal', -> 'Tax Exempt: State'
            input name:'billing_information.tax_exempt.state', class:'required minlength(2)'

            label  for:'billing_information.tax_exempt.local', class:'normal', -> 'Tax Exempt: Local'
            input name:'billing_information.tax_exempt.local', class:'required minlength(2)'

            label  for:'billing_information.tax_exempt.county', class:'normal', -> 'Tax Exempt: County'
            input name:'billing_information.tax_exempt.county', class:'required minlength(2)'

          div id:'billing_location_contact',  class:'form', ->

            label  for:'billing_location.contact.name', class:'normal', -> 'Billing Contact Name'
            input name:'billing_location.contact.name', class:'required minlength(2)'

            label  for:'billing_location.contact.phone', class:'normal', -> 'Billing Contact Tel #'
            input name:'billing_location.contact.phone', class:'required minlength(2)'

            label  for:'billing_location.contact.email', class:'normal', -> 'Billing Contact Email'
            input name:'billing_location.contact.email', class:'required minlength(2)'

        div id:'accounts_payable', class:'form', ->

          label  for:'accounts_payable.name', class:'normal', -> 'Accounts Payable Contact Name'
          input name:'accounts_payable.name', class:'required minlength(2)'

          label  for:'accounts_payable.phone', class:'normal', -> 'Accounts Payable Contact Telephone Number'
          input name:'accounts_payable.phone', class:'required minlength(2)'

          label  for:'accounts_payable.email', class:'normal', -> 'Email address where bills are to be sent'
          input name:'accounts_payable.email', class:'required minlength(2)'

        div id:'billing_method', class:'form', ->
          p  class:'normal', -> 'Billing Method Requested (Subject to review and credit approval)'

          label  for:'billing_method.billing_method', class:'normal', -> 'Billing method'
          select name:'billing_method.billing_method', class:'normal', ->
            option value:'card', class:'normal', ->'Credit Card'
            option value:'ach', class:'normal', ->'ACH'
            option value:'account', class:'normal', ->'Existing Sotel Account'

        div id:'payment_information', class:'form', ->
          p  class:'normal', -> 'Credit Card / ACH Payment Information'

          label  for:'payment_information.years_at_location', class:'normal', -> 'Years at current location'
          input name:'payment_information.years_at_location', class:'required minlength(2)'

          label  for:'payment_information.federal_id', class:'normal', -> 'Federal ID #'
          input name:'payment_information.federal_id', class:'required minlength(2)'

          label  for:'payment_information.dnb_number', class:'normal', -> 'D&B Number'
          input name:'payment_information.dnb_number', class:'required minlength(2)'

          div id:'payment_information_card', class:'form', ->

            label  for:'payment_information.card.type', class:'normal', -> 'Credit Card Type'
            input name:'payment_information.card.type', class:'required minlength(2)'

            label  for:'payment_information.card.number', class:'normal', -> 'Card Number'
            input name:'payment_information.card.number', class:'required minlength(2)'

            label  for:'payment_information.card.month', class:'normal', -> 'Expiration Month'
            input name:'payment_information.card.month', class:'required minlength(2)'

            label  for:'payment_information.card.year', class:'normal', -> 'Expiration Year'
            input name:'payment_information.card.year', class:'required minlength(2)'

            label  for:'payment_information.card_name', class:'normal', -> 'Name on card'
            input name:'payment_information.card.name', class:'required minlength(2)'

            label  for:'payment_information.card.ccv', class:'normal', -> 'Card CCV'
            input name:'payment_information.card.ccv', class:'required minlength(2)'

          div id:'payment_information_ach', class:'form', ->

            label  for:'payment_information.bank.company', class:'normal', -> 'Banking Institution'
            input name:'payment_information.bank.company', class:'required minlength(2)'

            label  for:'payment_information.bank.aba_number', class:'normal', -> 'ABA #'
            input name:'payment_information.bank.aba_number', class:'required minlength(2)'

            label  for:'payment_information.bank.address_1', class:'normal', -> 'Address'
            input name:'payment_information.bank.address_1', class:'required minlength(2)'

            label  for:'payment_information.bank.address_2', class:'normal', -> 'Address (line 2)'
            input name:'payment_information.bank.address_2', class:' minlength(2)'

            label  for:'payment_information.bank.city', class:'normal', -> 'City'
            input name:'payment_information.bank.city', class:'required minlength(2)'

            label  for:'payment_information.bank.state', class:'normal', -> 'State'
            input name:'payment_information.bank.state', class:'required minlength(2)'

            label  for:'payment_information.bank.postal_code', class:'normal', -> 'ZIP Code'
            input name:'payment_information.bank.postal_code', class:'required minlength(2)'

            label  for:'payment_information.bank.contact_name', class:'normal', -> 'Bank Contact'
            input name:'payment_information.bank.contact_name', class:'required minlength(2)'

          div id:'payment_information_account', class:'form', ->

            label  for:'payment_information.account.number', class:'normal', -> 'Sotel Account Number'
            input name:'payment_information.account.number', class:'required minlength(2)'

            label  for:'payment_information.account.contact_name', class:'normal', -> 'Sotel Contact Name'
            input name:'payment_information.account.contact_name', class:'required minlength(2)'


        div id:'references', class:'form', ->

          p  class:'normal', -> 'OPEN Account References'

          for i in [1..3]

            div id:"reference_#{i}",  class:'form', ->
              p  class:'normal', -> "Reference ##{i}"

              label  for:"reference[#{i}].company", class:'normal', -> 'Company'
              input name:"reference[#{i}].company", class:'required minlength(2)'

              label  for:"reference[#{i}].address_1", class:'normal', -> 'Address'
              input name:"reference[#{i}].address_1", class:'required minlength(2)'

              label  for:"reference[#{i}].address_2", class:'normal', -> 'Address (line 2)'
              input name:"reference[#{i}].address_2", class:' minlength(2)'

              label  for:"reference[#{i}].city", class:'normal', -> 'City'
              input name:"reference[#{i}].city", class:'required minlength(2)'

              label  for:"reference[#{i}].state", class:'normal', -> 'State'
              input name:"reference[#{i}].state", class:'required minlength(2)'

              label  for:"reference[#{i}].postal_code", class:'normal', -> 'ZIP Code'
              input name:"reference[#{i}].postal_code", class:'required minlength(2)'

              label  for:"reference[#{i}].contact_name", class:'normal', -> 'Contact Name'
              input name:"reference[#{i}].contact_name", class:'required minlength(2)'

              label  for:"reference[#{i}].phone", class:'normal', -> 'Phone'
              input name:"reference[#{i}].phone", class:'required minlength(2)'

              label  for:"reference[#{i}].fax", class:'normal', -> 'Fax'
              input name:"reference[#{i}].fax", class:'required minlength(2)'

      div id:'step-3', ->
        h2 class:'stepTitle', -> 'Billing Information'

        div id:'service_information', class:'form', ->

          p  class:'normal', -> 'Service Information'

          label  for:'service_information.main_billing_number', class:'normal', -> 'Current Main Billing Telephone Number'
          input name:'service_information.main_billing_number', class:'required minlength(2)'

          label  for:'service_information.current_lec', class:'normal', -> 'Current Service Provider LEC'
          input name:'service_information.current_lec', class:'required minlength(2)'

          label  for:'service_information.ld_carrier', class:'normal', -> 'LD Carrier'
          input name:'service_information.ld_carrier', class:'required minlength(2)'

          label  for:'service_information.broadband_sp', class:'normal', -> 'Broadband Service Provider'
          input name:'service_information.broadband_sp', class:'required minlength(2)'

          label  for:'service_information.broadband_service_type', class:'normal', -> 'Broadband Service Type'
          input name:'service_information.broadband_service_type', class:'required minlength(2)'

          label  for:'service_information.broadband_service_speed', class:'normal', -> 'Broadband Service Speed'
          input name:'service_information.broadband_service_speed', class:'required minlength(2)'


      div id:'step-5', ->
        h2 class:'stepTitle', -> 'Technical Contact'

        div id:'technical_contact', class:'form', ->

          label  for:'technical_contact.name', class:'normal', -> 'Technical Contact Name'
          input name:'technical_contact.name', class:'required minlength(2)'

          label  for:'technical_contact.phone', class:'normal', -> 'Technical Contact Phone'
          input name:'technical_contact.phone', class:'required minlength(2)'

          label  for:'technical_contact.email', class:'normal', -> 'Technical Contact Email'
          input name:'technical_contact.email', class:'required minlength(2)'

      div id:'step-6', ->
        h2 class:'stepTitle', -> 'Terms and Conditions, Signature'

        div id:'signature', class:'form', ->

          p  class:'normal', -> 'Signature Card'

          # label  for:'signature.sign', class:'normal', -> 'Authorized Customer Signature / Responsible Officer'
          # input name:'signature.sign', class:'required minlength(2)'

          label  for:'billing_information.agree_electronic_delivery', class:'normal', -> 'I agree to electronic delivery of all invoices (type YES)'
          input name:'billing_information.agree_electronic_delivery', class:'required minlength(2)'

          label  for:'signature.name', class:'normal', -> 'Name of Authorized Customer / Responsible Officer'
          input name:'signature.name', class:'required minlength(2)'

          label  for:'signature.date', class:'normal', -> 'Date'
          input name:'signature.date', class:'required minlength(2)'

          label  for:'signature.title', class:'normal', -> 'Title'
          input name:'signature.title', class:'required minlength(2)'

      div id:'step-7', ->
        h2 class:'stepTitle', -> 'Confirmation'

        p class:'normal', -> '''
            Thank you for your order.
            '''

