l = (_id,_label,_class) ->
  div class:'form_line', ->
    label for: _id, -> _label
    input name: _id, class: _class

#
# Will need to store the "plans" characteristics somewhere
# (but they are essentially products just like the ones in the quoting engine).
#

client:
  $('.product_list .quantity').hide()

view:
  table class:'product_list',->
    for product in @products
      tr id:@product._id, class:'product',->
        td class:'product_select'     ,->
          input type:'checkbox', class:'product_check', name:"#{@plan._id}.selected"
        td class:'product_picture'    ,->
          img src:"/products/#{@product._id}/picture.png"
        td class:'product_description',->
          @product.description
        td class:'product_unit_price' ,->
          @product.unit_price
        td class:'quantity'           ,->
          input name:"#{@product._id}.quantity"
        td class:'add'                ,->
          button class:'product_add', -> 'Add'

