l = (_id,_label,_class) ->
  div class:'form_line', ->
    label for: _id, -> _label
    input name: _id, class: _class

div id:'reg_common',->

  l 'first_name', 'First Name', 'required minlength(2)'
  l 'last_name',  'Last Name',  'required minlength(2)'
  l 'email',      'Email',      'required email'
  l 'phone',      'Phone',      'required phone'

