# TODO Refactor using sammy.form.js and sammy.form_2_json.js

@include = ->
  coffee '/p/partner_signup.js': ->

    $('#partner_signup_trigger').click ->

        $('#content').html 'Please wait, loading...'

        $('#content').load '/p/partner_signup.html', ->

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

          $.getJSON '/u/profile.json', (profile) ->
            $.couch.urlPrefix = profile.userdb_base_uri
            $('#wizard_form').set_couchdb_name(profile.user_database)

          # Clear the form (alternatively, could use load_couchdb_item()
          $('#wizard_form').new_couchdb_item()

          console.log 'Configuring form'

          ajaxSubmit = (was_validated)->
            console.log "Submitting with was_validated = #{was_validated}"
            $('#wizard_form').each ->
              $(@).data('ldoc').was_validated = was_validated
              $(@).data('ldoc').type = 'partner_signup'
              $(@).save_couchdb_item ->
                $('#confirm_invalid').dialog 'close'

          $('form.validate').validate

            debug: true

            submitHandler: (form)->
              $(form).each ->
                ajaxSubmit true

            invalidHandler: (form)->
              console.log 'invalidHandler'

              $('#confirm_invalid').dialog('open')

          # Form interaction

          # -- Siemens_mx --
          update_siemens_mx = ->
            value = $('[name="products.siemens_mx"]').val()
            console.log "Value is #{value}"
            if value
              $("#siemens_mx").show()
            else
              $("#siemens_mx").hide()


          $('[name="products.siemens_mx"]').change update_siemens_mx
          update_siemens_mx()

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

          console.log 'Starting wizard'
          $('#wizard').smartWizard({})
          
  get '/p/partner_signup.html': ->
    render 'partner_signup', layout:no

  view partner_signup: ->

    checkbox = (name,title) ->
      label  for:name, class:'normal', -> title
      input name:name, type:'checkbox', value:'yes'

    textbox = (name,title,some_class) ->
      label  for:name, class:'normal', -> title
      input name:name, class:some_class

    text_area = (name,title) ->
      label  for:name, class:'normal', -> title
      textarea name:name, rows:3, cols:72

    div id:'confirm_invalid', ->
      p -> 'The form contains errors.'

    form id:'wizard_form', method:'post', class:'validate', ->

      div id:"wizard", class:"swMain", ->
        ul ->
          li -> a href:'#intro', ->
            label class:'stepNumber', -> 0
            span class:'stepDesc', -> 'Introduction<br/><small></small>'
          li -> a href:'#step-1', ->
            label class:'stepNumber', -> 1
            span class:'stepDesc', -> 'Step 1<br/><small>Partner Category</small>'
          li -> a href:'#step-2', ->
            label class:'stepNumber', -> 2
            span class:'stepDesc', -> 'Step 2<br/><small>Contact Information</small>'
          li -> a href:'#step-3', ->
            label class:'stepNumber', -> 3
            span class:'stepDesc', -> 'Step 3<br/><small>Background Information</small>'
          li -> a href:'#step-4', ->
            label class:'stepNumber', -> 4
            span class:'stepDesc', -> 'Step 4<br/><small>Technical Background</small>'
          li -> a href:'#step-5', ->
            label class:'stepNumber', -> 5
            span class:'stepDesc', -> 'Step 5<br/><small>Sotel On-boarding</small>'
          li -> a href:'#step-6', ->
            label class:'stepNumber', -> 6
            span class:'stepDesc', -> 'Step 6<br/><small>Terms and Conditions, Signature</small>'
          li -> a href:'#done', ->
            label class:'stepNumber', -> 7
            span class:'stepDesc', -> 'Confirmation<br/><small></small>'

        div id:'intro', ->
          h2 class:'stepTitle', -> 'Introduction'

          p -> 'Thank you for your interest in becoming a SoTel Partner!'

          p -> "What you'll need: ..."


          div id:'agent', class:'form', ->

            p  class:'normal', -> 'Company Information'

            textbox 'agent.company',        'Agent Company',  'required minlength(2)'
            textbox 'agent.main_number',    'Main Number',    'required phone minlength(2)'
            textbox 'agent.website',        'Website',        'required url minlength(6)'
            textbox 'agent.address_1',      'Address',        'required minlength(2)'
            textbox 'agent.address_2',      'Address (line 2)', 'minlength(2)'
            textbox 'agent.city',           'City',           'required minlength(2)'
            textbox 'agent.state',          'State',          'required minlength(2)'
            textbox 'agent.postal_code',    'ZIP Code',       'required minlength(2)'

        div id:'step-1', ->
          h2 class:'stepTitle', -> 'Partner Category'

          div id:'products',  class:'form', ->

            checkbox  'products.sotel_sip_service',   'SoTel SIP Service'
            checkbox  'products.sotel_video_conf',    'SoTel Video Conferencing'
            checkbox  'products.siemens_mx',          'Siemens OpenScape Office MX'

        div id:'step-2', ->
          h2 class:'stepTitle', -> 'Contact Information'

          for i in [0..1]
            p -> if i == 0 then 'Primary Contact' else 'Alternate Contact'

            label  for:"contacts[#{i}].address_1", class:"normal",  class:"normal", -> "Address"
            input name:"contacts[#{i}].address_1", class:"required text minlength(2)"

            label  for:"contacts[#{i}].address_2", class:"normal", -> "Address (line 2)"
            input name:"contacts[#{i}].address_2", class:"text minlength(2)"

            label  for:"contacts[#{i}].city", class:"normal", -> "City"
            input name:"contacts[#{i}].city", class:"required text minlength(2)"

            label  for:"contacts[#{i}].state", class:"normal", -> "State"
            input name:"contacts[#{i}].state", class:"required text minlength(2)"

            label  for:"contacts[#{i}].postal_code", class:"normal", -> "ZIP Code"
            input name:"contacts[#{i}].postal_code", class:"required digits minlength(2)"

            div class:"form", ->

              label  for:"contacts[#{i}].contact.name", class:"normal", -> "Contact Name"
              input name:"contacts[#{i}].contact.name", class:"required name minlength(2)"

              label  for:"contacts[#{i}].contact.phone", class:"normal", -> "Contact Telephone"
              input name:"contacts[#{i}].contact.phone", class:"required phoneUS minlength(2)"

              label  for:"contacts[#{i}].contact.email", class:"normal", -> "Contact Email"
              input name:"contacts[#{i}].contact.email", class:"required email minlength(2)"



        div id:'step-3', ->
          h2 class:'stepTitle', -> 'Background Information'

          label  for:'business.employees.total', class:'normal', -> 'Total Employees'
          input name:'business.employees.total', class:'required number'
          label  for:'business.employees.sales', class:'normal', -> '.. Allocated to Sales'
          input name:'business.employees.sales', class:'required number'
          label  for:'business.employees.operations', class:'normal', -> '.. Allocated to Operations'
          input name:'business.employees.operations', class:'required number'
          label  for:'business.employees.install_support', class:'normal', -> '.. Allocated to Service and Installation Support'
          input name:'business.employees.install_support', class:'required number'

          p -> 'Target Market segment by model line size'
          label  for:'business.line_size.2to24', class:'normal', -> '.. 2 to 24 users'
          input name:'business.line_size.2to24', class:'required number'
          label  for:'business.line_size.24to50', class:'normal', -> '.. 25 to 50 users'
          input name:'business.line_size.24to50', class:'required number'
          label  for:'business.line_size.51to100', class:'normal', -> '.. 51 to 100 users'
          input name:'business.line_size.51to100', class:'required number'
          label  for:'business.line_size.100more', class:'normal', -> '.. 100 users or more'
          input name:'business.line_size.100more', class:'required number'

          p -> 'Revenue'

          label  for:'business.revenue', class:'normal', -> 'Average revenue over the last three years for telecom-related sales'
          input name:'business.revenue', class:'required number'

          p -> 'Please lit the Equipment (by manufacturer) /Services that you Provide to your Current Customer Base.'
          p -> 'Please list the Current Telecom, Voice, Video and Data Solutions supported.'

          for i in [1..4]
            text_area "business.solution[#{i}]", i

          p -> 'Current Services Provided by your company'
          
          checkbox 'business.services.voice_sales_design',    'Voice Sales/Design'
          checkbox 'business.services.voice_mgmt',            'Voice Project Management, Training, and Implementation'
          checkbox 'business.services.voice_support',         'Onsite and Remote Level 1 Support'
          checkbox 'business.services.network_sales_design',  'Network Sales/Design'
          checkbox 'business.services.network_mgmt',          'Network Project Management, and LAN/WAN Implementation'
          checkbox 'business.services.network_support',       'Network Onsite and Remote Support'

          p -> 'Target Vertical Markets. Does your company concentrate on any particular Telecom / UC vertical market segments? Please Describe.'
          text_area 'business.verticals', 'Target Vertical Markets'

          
        div id:'step-4', ->
          h2 class:'stepTitle', -> 'Technical Background'


          checkbox 'technical.network.certified', 'Partner is certified to design, implement and support LAN/WAN infrastructures'
          text_area 'technical.network.certifications', 'Please list any current Network Design / Architecture certifications.'

          p -> 'Technical Background Detail'

          checkbox 'technical.knows.network', 'Base knowledge of networking principles'
          checkbox 'technical.knows.ips',     'Knowledge of IP address assignments'
          checkbox 'technical.knows.vlans',   'Knowledge of VLAN differentials'
          checkbox 'technical.knows.fw',      'Knowledge of firewall configuration, port forwarding and static routing'
          checkbox 'technical.knows.dns',     'Knowledge of  DNS name assignment'
          checkbox 'technical.knows.routing', 'Knowledge of multiple network connections and routing'
          text_area 'technical.knows.manufacturer_certifications', 'What other manufacture certifications do you presently maintain.'

          text_area 'marketing.how', 'How did you hear about SoTel Systems'
   
          div id:'siemens_mx', ->
            text_area 'siemens_mx.reason', "Reason for partner’s interest in picking up the Siemens OpenScape Solution."
            checkbox 'siemens_mx.training', "Partner will commit to allocate resources to attend and complete all Siemens OpenScape Office related Sales and maintenance training within 2 months from the becoming a registered Sotel partner and reseller of the Siemens OpenScape Office solution."
            checkbox 'siemens_mx.demo', "Partner has agreed to purchase a Siemens OpenScape Office MX demonstration system as part of their first stocking order with Sotel."


        div id:'step-5', ->
          h2 class:'stepTitle', -> 'Sotel On-boarding'

          p -> ' SoTel On-Boarding Documentation and Process'

          p -> "We appreciate you taking the time to fill out the Partnership Form.  We will review your application as soon as possible.  Once the form has been reviewed and accepted, we will be reaching back out to you to provide information on the SoTel partnership.  "

          p -> "As part of the on-boarding process your Sotel systems representative will be contacting you to provide you information concerning our processes. "

          ol ->
            li 'Ordering and Logistics'
            li 'Process Support and escalation'
            li 'Service Support and escalation'
            li 'Web portal navigation'
            li 'Product Education'
            li "Accessing the Sotel and Manufacturer’s web portals"

          p -> "In order to set up your access for product support and the manufacturer web portal(s) we will also need the following information for each of your employees."

          table id:'onboarding',  class:'form auto_add', ->

            tr ->
              th -> 'First Name'
              th -> 'Last Name'
              th -> 'Function'
              th -> 'Phone'
              th -> 'EMail'

            tr class:'template', ->
              td -> input name:'onboarding[*].first_name', class:'required minlength(2)'
              td -> input name:'onboarding[*].last_name', class:'required minlength(2)'
              td -> input name:'onboarding[*].function', class:'required minlength(2)'
              td -> input name:'onboarding[*].phone', class:'required minlength(2)'
              td -> input name:'onboarding[*].email', class:'required minlength(2)'

        div id:'step-6', ->
          h2 class:'stepTitle', -> 'Terms and Conditions, Signature'

          div id:'signature', class:'form', ->

            p  class:'normal', -> 'Signature Card'

            label  for:'signature.name', class:'normal', -> 'Name of Authorized / Responsible Officer'
            input name:'signature.name', class:'required minlength(2)'

            label  for:'signature.date', class:'normal', -> 'Date'
            input name:'signature.date', class:'required minlength(2)'

            label  for:'signature.title', class:'normal', -> 'Title'
            input name:'signature.title', class:'required minlength(2)'

        div id:'done', ->
          h2 class:'stepTitle', -> 'Confirmation'

