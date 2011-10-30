normalized_phone_number = (number) ->
  # By convention CCNQ3 will use 'E.164-without-plus-sign'
  # as the normalized form for phone numbers.

  # US numbers
  number.replace /^([2-9]\d\d[2-9]\d\d\d{4})$/, '+1$1'
  number.replace /^(1[2-9]\d\d[2-9]\d\d\d{4})$/, '+$1'
  # FR number
  number.replace /^0(\d{9})$/, '+33$1'
  # etc. (replace the code above with your own functions)
  return number


    # Example for US and French numbers.
    coffeescript
      $('.phone').change ->
        number = $(@).val()
        $(@).val normalized_phone_numbers number

