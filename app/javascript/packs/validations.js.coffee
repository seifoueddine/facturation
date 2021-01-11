class window.Validation

  @UserSettingForm = ->
    $('#sub_user_form').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      ignore: 'input[type=hidden]'
      rules:
        user_name: required: true
        email: required: true
        role_id: required: true
        password: required: true
        password_confirmation:
          required: true

      messages:
        user_name: required: 'Name cannot be blank'
        email:  required: 'Email cannot be blank'
        role_id: required: 'Role cannot be blank'
        password: required: 'Password cannot be blank'
        password_confirmation: required: 'Password confirmation cannot be blank'


  @CompanySettingForm = ->
    $('#companyForm').submit ->
      $('.invalid-error').removeClass('hidden')
    $('.invalid-error').removeClass('hidden')
    $('#companyForm').validate
      onfocusout: (element) ->
        if !($("label[for='" + $(element).attr('id') + "']").hasClass('active'))
          $(element).valid()
        else
          $('#'+element.id+'-error').addClass('hidden')
      onkeyup: (element) ->
        $('#'+element.id+'-error').removeClass('hidden')
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      
      errorPlacement: ($error, $element) ->
        if ($element.attr('name') == 'company[logo]')
          $('.file-field').append $error

      rules:
        'company[company_name]': required: true
        'company[contact_name]': required: true
        'company[email]': required: true
        'company[logo]': accept: 'jpg,jpeg,png'
      messages:
        'company[company_name]': required: 'Company name cannot be blank'
        'company[contact_name]': required: 'Contact name cannot be blank'
        'company[email]': required: 'Email cannot be blank'
        'company[logo]': accept: 'Please upload image in these format only (jpg, jpeg, png).'

      $('.file-path').on 'change', ->
        $('#company_logo').valid()


  @RoleSettingForm = ->
    $('#new_role').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'role[name]': required: true
      messages:
        'role[name]': required: 'Name cannot be blank'


  @InvoiceForm = ->
    $('.invoice-client-select').on 'focusout', (e) ->
      $('#invoice_client_id').valid()

    $('#s2id_invoice_invoice_line_items_attributes_0_item_id').on 'focusout', (e) ->
      $('#invoice_invoice_line_items_attributes_0_item_id').valid()

    jQuery.validator.addMethod 'lessThan', ((value, element) ->
          return value <= $('#invoice_due_date_picker').val()
      ), 'Invoice date cannot be greater than due date'

    jQuery.validator.addMethod 'greaterThan', ((value, element) ->
          return value >= $('#invoice_date_picker').val()
      ), 'Due date cannot be less than invoice date'

    $('.invoice-form').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      ignore: 'input[type=hidden]'
      rules:
        'invoice[client_id]': required: true
        'invoice[recurring_schedule_attributes][delivery_option]': required: '#recurring:checked'
        'invoice[invoice_date]': lessThan: true
        'invoice[due_date]': greaterThan: true
        'invoice[invoice_line_items_attributes][0][item_id]': required: true
      messages:
        'invoice[client_id]': required: 'Client cannot be blank'
        'invoice[invoice_line_items_attributes][0][item_id]': required: 'Item cannot be blank'
        'invoice[recurring_schedule_attributes][delivery_option]': required: 'Select at least one delivery option'

      errorPlacement: ($error, $element) ->
        if ($element.attr('name') == 'invoice[client_id]')
          $('#s2id_invoice_client_id').append $error
        else if ($element.attr('name') == 'invoice[recurring_schedule_attributes][delivery_option]')
          $('.invoice_recurring_schedule_delivery_option').append $error
        else
          $error.insertAfter($element);

      jQuery.validator.addClassRules
        cost: min: 0
      jQuery.validator.addClassRules
        qtyy: min: 0

      jQuery.validator.messages.min = "Value should not be less than 0"



  @EstimateForm = ->
    $('.estimate-select-client').on 'focusout', (e) ->
      $('#estimate_client_id').valid()

    $('#s2id_estimate_estimate_line_items_attributes_0_item_id').on 'focusout', (e) ->
      $('#estimate_estimate_line_items_attributes_0_item_id').valid()

    $('.estimate-form').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      ignore: 'input[type=hidden]'
      rules:
        'estimate[client_id]': required: true
        'estimate[estimate_line_items_attributes][0][item_id]': required: true
      messages:
        'estimate[client_id]': required: 'Client cannot be blank'
        'estimate[estimate_line_items_attributes][0][item_id]': required: 'Item cannot be blank'



  @ItemForm = ->
    $('.item_form').submit ->
      $('.invalid-error').removeClass('hidden')
    $('.invalid-error').removeClass('hidden')
    $('.item_form').validate
      onfocusin: (element) ->
        $(element).valid()
      onfocusout: (element) ->
        if !($("label[for='" + $(element).attr('id') + "']").hasClass('active'))
          $(element).valid()
        else
          $('#'+element.id+'-error').addClass('hidden')
      onkeyup: (element) ->
        $('#'+element.id+'-error').removeClass('hidden')
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'item[item_description]': required: true
        'item[unit_cost]': required: true, number: true
        'item[quantity]': required: true, number: true
        'item[item_name]': required: true, remote: {url: "/items/verify_item_name", type: "get", dataType: 'json', data: {
          'item_id': ->
            $('.item_id').html()
          'item_name': ->
            $('#item_item_name').val()
          'newItem': ->
            if ($('.item_form').hasClass('edit_item'))
              'edit_item'
        }
        }

      messages:
        'item[item_name]': required: 'Name cannot be blank', remote: 'Item with same name already exists'
        'item[item_description]': required: 'Description cannot be blank'
        'item[unit_cost]': required: 'Unit cost cannot be blank', number: 'Unit cost must be in numeric'
        'item[quantity]': required: 'Quantity cannot be blank', number: 'Quantity must be in numeric'



  @TaxForm = ->
    $('.tax_form').submit ->
      $('.invalid-error').removeClass('hidden')
    $('.invalid-error').removeClass('hidden')
    $('.tax_form').validate
      onfocusout: (element) ->
        if !($("label[for='" + $(element).attr('id') + "']").hasClass('active'))
          $(element).valid()
        else
          $('#'+element.id+'-error').addClass('hidden')
      onkeyup: (element) ->
        $('#'+element.id+'-error').removeClass('hidden')
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'tax[percentage]': required: true, number: true, max: 100
        'tax[name]': required: true, remote: {url: "/taxes/verify_tax_name", type: "get", dataType: 'json', data: {
          'tax_id': ->
            $('.tax_id').html()
          'tax_name': ->
            $('#tax_name').val()
          'newTax': ->
            if ($('.tax_form').hasClass('edit_tax'))
              'edit_tax'
        }
        }
      messages:
        'tax[percentage]': required: 'Percentage cannot be blank', number: 'Percentage must be in numeric', max: 'Tax percentage cannot exceeds to 100%'
        'tax[name]': required: 'Name cannot be blank', remote: 'Tax with same name already exists'



  @ClientForm = ->
    $('#newClient').submit ->
      $('.invalid-error').removeClass('hidden')
    $('.invalid-error').removeClass('hidden')

    jQuery.validator.addMethod 'emailRegex', ((value, element) ->
      return this.optional( element ) || /^.+@.+\..+$/.test( value );
    ), 'Please enter a valid email address'

    $('#newClient').validate
      onfocusin: (element) ->
        $(element).valid()
      onfocusout: (element) ->
        if !($("label[for='" + $(element).attr('id') + "']").hasClass('active'))
          $(element).valid()
        else
          $('#'+element.id+'-error').addClass('hidden')
      onkeyup: (element) ->
        $('#'+element.id+'-error').removeClass('hidden')
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'client[organization_name]': required: true
        'client[first_name]': required: true
        'client[last_name]': required: true
        'client[email]': required: true, emailRegex: true, remote: {url: "/clients/verify_email", type: "get", dataType: 'json', data: {
          'client_id': ->
            $('.client_id').html()
          'email': ->
            $('#client_email').val()
          'newClient': ->
            if ($('#newClient').hasClass('edit_client'))
              'edit_client'
        }
        }
      messages:
        'client[organization_name]': required: 'Organization name cannot be blank'
        'client[first_name]': required: 'First name cannot be blank'
        'client[last_name]': required: 'Last name cannot be blank'
        'client[email]': required: 'Email cannot be blank', remote: "Email already exists"



  @PaymentForm = ->
    jQuery.validator.addMethod 'lessThanOrEqualToDueAmount', ((value, element) ->
      return value <= parseFloat($('.due_amount').html())
    ), 'Amount should not be greater than remaining amount'

    $('#payments_form').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'

      jQuery.validator.addClassRules
        payment_amount: required: true, number: true, min: 1, lessThanOrEqualToDueAmount: '.paid_full:checked'

      jQuery.validator.messages.required = "Amount cannot be blank"
      jQuery.validator.messages.number = "Please enter a valid amount"
      jQuery.validator.messages.min = "Amount should be greater than 0"


      $('.payment_right').each ->
        parent = $(this)
        $(this).find('.paid_full').on 'change', ->
          parent.find('.payment_amount').valid()

    $('#new_payment').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'payment[payment_amount]': required: true, number: true, min: 1, lessThanOrEqualToDueAmount: '.paid_full:checked'
      messages:
        'payment[payment_amount]': required: 'Amount cannot be blank', number: 'Please enter a valid amount',
        min: 'Amount should be greater than 0'

      $('#payment_paid_full').on 'change', ->
        $('#payment_payment_amount').valid()


  @recurringFrequencyForm = ->
    $('.recurring_frequency_form').validate
      onfocusout: (element) ->
        $(element).valid()
      onkeyup: (element) ->
        $(element).valid()
      errorClass: 'error invalid-error'
      errorElement: 'span'
      rules:
        'recurring_frequency[title]': required: true
        'recurring_frequency[number_of_days]': required: true, number: true, min: 0
      messages:
        'recurring_frequency[title]': required: 'Title is required'
        'recurring_frequency[number_of_days]': required: 'Number of days are required', number: 'Please enter only numbers', min: 'Number of days cannot be negative'
