# partner_signup.coffee

do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  profile = $(container).data 'profile'

  partner_signup_tpl = $.compile_template ->

    form id:'wizard_form', method:'post', action:'#/partner_signup', class:'validate', ->

      input type:'hidden', name:'was_validated'

      input type:'hidden', name:'accept_agreements', id:'accept_agreements'

      div id:'tc_dialog', ->
        div id:'agent-agreement', class:'agreement'
        div id:'mutual-non-disclosure-agreement', class:'agreement'
        div id:'partner-usage-agreement', class:'agreement'
        div id:'technical-services', class:'agreement'
        div id:'wholesale-services-agreement', class:'agreement'

      coffeescript ->
        $('#tc_dialog').dialog
          autoOpen:false
          modal:true
          closeOnEscape: true
          width: '80%'
          buttons:
            'Print': ->
              window.print()
            'Accept': ->
              $('#accept_agreements').val(true)
              $('#tc_dialog').dialog('close')


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
            span class:'stepDesc', -> 'Step 5<br/><small>Contacts</small>'
          li -> a href:'#step-6', ->
            label class:'stepNumber', -> 6
            span class:'stepDesc', -> 'Step 6<br/><small>Terms and Conditions, Signature</small>'
          li -> a href:'#done', ->
            label class:'stepNumber', -> 7
            span class:'stepDesc', -> 'Confirmation<br/><small></small>'

        div id:'intro', ->
          h2 class:'stepTitle', -> 'Introduction'

          p -> 'Thank you for your interest in becoming a SoTel Systems Partner!'

          p -> "What you'll need: You will need your company's information as well as contact details for anyone you want to have immediate access to this portal."

          div id:'agent', class:'form', ->

            p  class:'normal', -> 'Company Information'

            textbox
              id:'agent.company'
              title:'Company Name'
              class:'required minlength(2)'
              value:@agent?.company
            textbox
              id:'agent.main_number'
              title:'Main Number'
              class:'required phone minlength(2)'
              value:@agent?.main_number
            textbox
              id:'agent.website'
              title:'Website'
              class:'required url minlength(6)'
              value:@agent?.website
            textbox
              id:'agent.address_1'
              title:'Address'
              class:'required minlength(2)'
              value:@agent?.address_1
            textbox
              id:'agent.address_2'
              title:'Address (line 2)'
              class:'minlength(2)'
              value:@agent?.address_2
            textbox
              id:'agent.city'
              title:'City'
              class:'required minlength(2)'
              value:@agent?.city
            textbox
              id:'agent.state'
              title:'State'
              class:'required minlength(2)'
              value:@agent?.state
            textbox
              id:'agent.postal_code'
              title:'ZIP Code'
              class:'required minlength(2)'
              value:@agent?.postal_code

        div id:'step-1', ->
          h2 class:'stepTitle', -> 'Partner Category'

          div id:'products',  class:'form', ->

            checkbox
              id:'products.sotel_sip_agency'
              title:'SIP Service Agency Program'
              value:@products?.sotel_sip_agency
            checkbox
              id:'products.sotel_sip_wholesale'
              title:'SIP Service Wholesale Program'
              value:@products?.sotel_sip_wholesale
            checkbox
              id:'products.sotel_videoconf'
              title:'Video Conferencing'
              value:@products?.sotel_videoconf
            checkbox
              id:'products.siemens_oo'
              title:'Siemens OpenScape Office'
              value:@products?.siemens_oo
            checkbox
              id:'products.epygi'
              title:'Epygi'
              value:@products?.epygi
            checkbox
              id:'products.snom'
              title:'snom'
              value:@products?.snom
            checkbox
              id:'products.sangoma'
              title:'Sangoma'
              value:@products?.sangoma

        coffeescript ->
          $('#products').delegate '#products.sotel_sip_agency', 'change', ->
            if $(@).val()?
              $('#forms.sotel_sip_agency').enable()
            else
              $('#forms.sotel_sip_agency').disable()
          # etc.

        div id:'step-2', ->
          h2 class:'stepTitle', -> 'Primary Contact Information'

          label  for:'primary_contact.contact.name', class:'normal', -> "Primary Contact Name"
          textbox
            id:'primary_contact.contact.name'
            title:'Primary Contact Name'
            class:'required'
            value: @primary_contact?.contact?.name or @profile.name
          textbox
            id:'primary_contact.contact.phone'
            title:'Primary Contact Phone Number'
            class:'required phone'
            value: @primary_contact?.contact?.phone or @profile.phone
          textbox
            id:'primary_contact.contact.email'
            title:'Primary Contact Email'
            class:'required email'
            value: @primary_contact?.contact?.email or @profile.email

        div id:'step-3', ->
          h2 class:'stepTitle', -> 'Background Information'

          textbox
            id:'business.employees.total'
            title:'Total Employees'
            class:'required number'
            value:@business?.employees?.total
          textbox
            id:'business.employees.sales'
            title:'.. Allocated to Sales'
            class:'required number'
            value:@business?.employees?.sales
          textbox
            id:'business.employees.operations'
            title:'.. Allocated to Operations'
            class:'required number'
            value:@business?.employees?.operations
          textbox
            id:'business.employees.install_support'
            title:'.. Allocated to Service and Installation Support'
            class:'required number'
            value:@business?.employees?.install_support

          p -> 'Target Market segment by model line size'
          checkbox
            id:'business.line_size.from2to24'
            title:'2 to 24 users'
            value:@business?.line_size?.from2to24
          checkbox
            id:'business.line_size.from24to50'
            title:'25 to 50 users'
            value:@business?.line_size?.from24to50
          checkbox
            id:'business.line_size.from51to100'
            title:'51 to 100 users'
            value:@business?.line_size?.from51to100
          checkbox
            id:'business.line_size.from100'
            title:'100 users or more'
            value:@business?.line_size?.from100

          p -> 'Revenue'

          textbox
            id:'business.revenue'
            title:'Average revenue over the last three years for telecom-related sales'
            class:'required number'
            value:@business?.revenue

          p -> 'Please list the Equipment (by manufacturer) /Services that you Provide to your Current Customer Base.'
          p -> 'Please list the Current Telecom, Voice, Video and Data Solutions supported.'

          text_area
            id:'business.solution.telecom'
            title:'Telecom'
            value:@business?.solution?.telecom
          text_area
            id:'business.solution.voice'
            title:'Voice'
            value:@business?.solution?.voice
          text_area
            id:'business.solution.video'
            title:'Video'
            value:@business?.solution?.video
          text_area
            id:'business.solution.data'
            title:'Data'
            value:@business?.solution?.data

          p -> 'Current Services Provided by your company'

          checkbox
            id:'business.services.voice_sales_design'
            title:'Voice Sales/Design'
            value:@business?.services?.voice_sales_design
          checkbox
            id:'business.services.voice_mgmt'
            title:'Voice Project Management, Training, and Implementation'
            value:@business?.services?.voice_mgmt
          checkbox
            id:'business.services.voice_support'
            title:'Onsite and Remote Level 1 Support'
            value:@business?.services?.voice_support
          checkbox
            id:'business.services.network_sales_design'
            title:'Network Sales/Design'
            value:@business?.services?.network_sales_design
          checkbox
            id:'business.services.network_mgmt'
            title:'Network Project Management, and LAN/WAN Implementation'
            value:@business?.services?.network_mgmt
          checkbox
            id:'business.services.network_support'
            title:'Network Onsite and Remote Support'
            value:@business?.services?.network_support

          p -> 'Target Vertical Markets. Does your company concentrate on any particular Telecom / UC vertical market segments? Please Describe.'
          text_area
            id:'business.verticals'
            title:'Target Vertical Markets'
            value:@business?.verticals

        div id:'step-4', ->
          h2 class:'stepTitle', -> 'Technical Background'


          checkbox
            id:'technical.network.certified'
            title:'Partner is certified to design, implement and support LAN/WAN infrastructures'
            value:@technical?.network?.certified
          text_area
            id:'technical.network.certifications'
            title:'Please list any current Network Design / Architecture certifications.'
            value:@technical?.network?.certifications

          p -> 'Technical Background Detail'

          checkbox
            id:'technical.knows.network'
            title:'Base knowledge of networking principles'
            value:@technical?.knows?.network
          checkbox
            id:'technical.knows.ips'
            title:'Proficiency of IP address assignments'
            value:@technical?.knows?.ips
          checkbox
            id:'technical.knows.vlans'
            title:'Proficiency of VLAN differentials'
            value:@technical?.knows?.vlans
          checkbox
            id:'technical.knows.fw'
            title:'Proficiency of firewall configuration, port forwarding and static routing'
            value:@technical?.knows?.fw
          checkbox
            id:'technical.knows.dns'
            title:'Proficiency of DNS name assignment'
            value:@technical?.knows?.dns
          checkbox
            id:'technical.knows.routing'
            title:'Proficiency of multiple network connections and routing'
            value:@technical?.knows?.routing
          text_area
            id:'technical.knows.manufacturer_certifications'
            title:'What other manufacture certifications do you presently maintain?'
            value:@technical?.knows?.manufacturer_certifications

        div id:'step-5', ->
          h2 class:'stepTitle', -> 'Contacts'

          p -> ' SoTel Systems On-Boarding Documentation and Process'

          p -> "We appreciate you taking the time to fill out the Partnership Form.  We will review your application as soon as possible.  Once the form has been reviewed and accepted, we will be reaching back out to you to provide information on the SoTel Systems partnership.  "

          p -> "As part of the on-boarding process your SoTel Systems representative will be contacting you to provide you information concerning our processes. "

          ol ->
            li 'Ordering and Logistics'
            li 'Process Support and escalation'
            li 'Service Support and escalation'
            li 'Web portal navigation'
            li 'Product Education'
            li "Accessing the SoTel Systems web portals"

          p -> "In order to set up your access for product support and the manufacturer web portal(s) we will also need the following information for each of your employees."

          table id:'onboarding',  class:'form', ->

            tr ->
              th -> 'First Name'
              th -> 'Last Name'
              th -> 'Function'
              th -> 'Phone'
              th -> 'EMail'

            for i in [0..4]
              do (i) ->
                tr class:'template', ->
                  td ->
                    input
                      name:"onboarding.#{i}.first_name"
                      class:'required minlength(2)'
                      value: @onboarding?[i]?.first_name
                  td ->
                    input
                      name:"onboarding.#{i}.last_name"
                      class:'required minlength(2)'
                      value: @onboarding?[i]?.last_name
                  td ->
                    input
                      name:"onboarding.#{i}.function"
                      class:'required minlength(2)'
                      value: @onboarding?[i]?.function
                  td ->
                    input
                      name:"onboarding.#{i}.phone"
                      class:'required minlength(2)'
                      value: @onboarding?[i]?.phone
                  td ->
                    input
                      name:"onboarding.#{i}.email"
                      class:'required minlength(2)'
                      value: @onboarding?[i]?.email

        div id:'step-6', ->
          h2 class:'stepTitle', -> 'Terms and Conditions, Signature'

          div id:'signature', class:'form', ->

            p  class:'normal', -> 'Signature Card'

            textbox
              id:'signature.name'
              title:'Name of Authorized / Responsible Officer'
              class:'required minlength(2)'
              value:@signature?.name

            textbox
              id:'signature.title'
              title:'Title'
              class:'required minlength(2)'
              value:@signature?.title

            textbox
              id:'signature.date'
              title:'Date'
              class:'required minlength(2)'
              readonly:true
              value:@signature?.date or @effective_date

        div id:'done', ->
          h2 class:'stepTitle', -> 'Confirmation'

          button id:'open_tc_dialog', 'Review and accept the Terms and Conditions'

        coffeescript ->
          $('#open_tc_dialog').click ->
            doc = $('#wizard_form').data 'doc'
            doc ?= {}
            $.extend doc, $('#wizard_form').toDeepJson()

            $('.agreement').each ->
              $(@).html '<img src="public/images/indicator.white.gif" />'
              $.get "/docs/#{@id}.html",
                (template) => $(@).html Milk.render template, doc
                'text'

            $('#tc_dialog').dialog 'open'
            return false

    coffeescript ->

      $('form.validate').validate
        onsubmit: false

      console.log 'Starting wizard'
      $('#wizard').smartWizard({})



  $(document).ready ->

    $.sammy container, ->

      app = @

      model = @createModel 'partner_signup'

      @get '#/partner_signup', ->

            data = $.extend {}, profile: profile.profile

            today = new Date()
            months = [
              'January','February','March','April','May','June',
              'July','August','September','October','November','December'
            ]
            data.effective_date = "#{months[today.getMonth()]} #{today.getDate()}, #{today.getFullYear()}"

            @send model.get, make_id('partner_signup',profile.name),
              success: (doc) =>
                console.log "Success"
                if doc.state isnt 'saved'
                  app.run '#/inbox'
                @swap partner_signup_tpl $.extend data, doc
                $('#wizard_form').data 'doc', doc
              error: =>
                console.log "Error"
                doc = {}
                @swap partner_signup_tpl $.extend data, doc
                $('#wizard_form').data 'doc', doc

      @bind 'save-doc', (event,new_state) ->

          $('.template').remove()

          doc = $('#wizard_form').data 'doc'
          doc ?= {}
          former_doc = doc
          $.extend doc, $('#wizard_form').toDeepJson()
          delete doc['onboarding.*']

          doc.type = 'partner_signup'  # set by Sammy.Couch.model.create()
          doc._id = make_id(doc.type,profile.name)
          doc[doc.type] = profile.name
          doc.state = new_state

          push_document = ->
            $.post '/roles/replicate/push/sotel_portal', (data)->
              if data.ok
                alert "Your application has been #{new_state}."
              else
                alert "Your application was not #{new_state}, please try again."
            , "json"

          if former_doc._rev?
            console.log 'Modify existing document'
            @send model.update, doc._id, doc,
              success: (resp) ->
                doc._rev = resp.rev
                $('#wizard_form').data 'doc', doc
                push_document()
          else
            console.log 'Save new document'
            delete doc._rev
            @send model.create,  doc,
              success: (resp) ->
                doc._rev = resp.rev # not really needed, done for symmetry
                $('#wizard_form').data 'doc', doc
                push_document()

      @post '#/partner_signup', ->
        console.log 'Partner form submission'

        form_is_valid = $('form.validate').valid()
        $('#was_validated').val form_is_valid

        if form_is_valid
          @trigger 'save-doc', 'submitted'
        else
          $('#confirm_invalid').empty()
          $(container).append '<div id="confirm_invalid"><p>The form contains errors.</p></div>'
          app = @

          options =
            buttons:
              'Correct now': ->
                $(@).dialog 'close'
              'Save for later': ->
                app.trigger 'save-doc', 'saved'
                $(@).dialog 'close'
              'Submit anyway': ->
                app.trigger 'save-doc', 'submitted'
                $(@).dialog('close')
            closeOnEscape: true
            draggable: true
            modal: true
            title: 'Errors in form'

          $('#confirm_invalid').dialog(options)

        return

      # Registers this application for the inbox.
      user_is = (role) ->
        profile.roles?.indexOf(role) >= 0

      partner_review_tpl = $.compile_template ->

        show = (name, t) ->
            span class:'name', -> "#{name}:"
            if typeof t is 'object'
              ul class:'value', ->
                (li -> show(k,v)) for k,v of t
            else
              span class:'value', -> t
        show 'Application content', @

        if @state is 'submitted'
          form method:'post', action:"#/partner_signup/update", ->
            hidden
              id:'id'
              value:@_id
            radio
              id:'state'
              value:'accepted'
              title:'Accepted'
            radio
              id:'state'
              value:'reject'
              title:'Rejected'
            radio
              id:'state'
              value:'saved'
              class:'state-saved'
              title:'Send back...'
            div class:'comment', ->
              span 'Add a comment:'
              input
                name:'comment'
                type:'textarea'
                value:''
            input
              type:'submit'
              value:'Submit'
            coffeescript ->
              $('.comment').hide()
              $('.state-saved').click -> $(@).siblings('.comment').show()

      @post '#/partner_signup/update', ->
        console.log "Updating #{@params.id} with state=#{@params.state} and comment=#{@params.comment}."
        @send model.get, @params.id,
          success: (doc) =>
            doc.state = @params.state
            doc.comment = @params.comment
            @send model.update, doc._id, doc
        return false

      Inbox.register 'partner_signup',

        list: (doc) ->
          if user_is 'sotel_partner_admin'
            switch doc.state
              when 'saved'
                return "Application has been sent back to partner for more information"
              when 'submitted'
                if doc.was_validated
                  return "Complete application submitted by #{doc.signature.name} from #{doc.agent.company}"
                else
                  return "Incomplete application submitted by #{doc.partner_signup}"
              when 'accepted'
                return "Accepted application for #{doc.agent.company}"
              when 'rejected'
                return "Rejected application for #{doc.agent.comapny}"
              else
                return "Application in unknown state #{doc.state}"
          else
            return "Your SoTel Partner application"

        form: (doc) ->
          if user_is 'sotel_partner_admin'
            partner_review_tpl doc
          else
            switch doc.state
              when 'saved'
                # Show comments if any!
                return "Your application is saved but has not been submitted yet. <a href=\"#/partner_signup\">Review and submit your application.</a>"
              when 'submitted'
                return "Your application has been submitted and is pending review."
              when 'accepted'
                return "Your application has been accepted."
              when 'rejected'
                return "Your application has been rejected."
              else
                return "No additional information is available."
