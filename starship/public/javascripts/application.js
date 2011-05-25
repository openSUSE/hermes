// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//to save and restore filter values
//var old_operator_hash = new Hash();
//var old_value_hash = new Hash();
//var special_operator_values = new Array('_mypackages', '_mypackagesstrict', '_myprojects','_myrequests', '_packagebugowner');


  function remove_filter(element) {
    $(element).parent().parent().remove();
    recalc_filter_ids();
    return false;
  }

  // updates all filter ids to be in the range [0..filter_count()[
  function recalc_filter_ids() {
    filters = $('#filter_table > .filter_line')
    $('#filter_count').val(filters.size());
    filters.each(function(index) {
        $(this).find('.param_select')[0].name = 'param_id_' + index;
        $(this).find('.param_select')[0].id = 'param_id_' + index;
        $(this).find('.filter_select')[0].name = 'filter_operator_' + index;
        $(this).find('.filter_select')[0].id = 'filter_operator_' + index;
        $(this).find('.filter_value_input')[0].name = 'filter_value_' + index;
        $(this).find('.filter_value_input')[0].id = 'filter_value_' + index;
    });


      //delete the old Observer and create a new one
      //stop_observer(operator_select);

      //add_observer(operator_select);

      //special_operator_checks(param_select);

  }


  function stop_observer(element) {
    Event.stopObserving(element,'change',function(event) {
      special_operator_checks(Event.element(event))
    });
  }

  function add_observer(element) {
    Event.observe(element,'change',function(event) {
      special_operator_checks(Event.element(event)) 
    });
  }

  //change the filter input to select box on special operator selection
  function special_operator_checks(element) {

    id = $(element).name.match(/.$/);

    param_elem = $('param_id_' + id);
    operator_elem = $('filter_operator_' + id);
    filter_elem = $("filter_value_" + id);

    old_oper_value = old_operator_hash.get(operator_elem.id);
    selected_param_value = param_elem.options[param_elem.selectedIndex].text
    
    if ($('filter_value_' + id))
      current_filter_value = $('filter_value_' + id).value;
    else
      current_filter_value = '';

    if(operator_elem.value == 'special') {
      param_elem.disabled = true;

      if (old_oper_value != 'special' && old_oper_value != '' && old_oper_value != undefined)
        old_value_hash.set(operator_elem.id, $('filter_value_' + id).value);

      filter_elem.replace(select_tag(id,current_filter_value));

    } else if(old_oper_value == 'special' && operator_elem.value != 'special'){

        param_elem.disabled = false;

        if (old_value_hash.get(operator_elem.id))
          filter_elem.replace(input_tag(id,old_value_hash.get(operator_elem.id)));
        else
          filter_elem.replace(input_tag(id,""));
       
    } 

   old_operator_hash.set(operator_elem.id,operator_elem.value);

  }

  function in_array(a,p){
   for (i=0;i<a.length;i++)
    if (a[i] == p) return true
   return false
  }

  function select_tag(id,selected){
    sel_string = '<select id=filter_value_' + id + ' name=filter_value_' + id +' class=filter_value_input';
    special_operator_values.each(function(s){
      if (selected == s)
        sel_string += ' <option selected=selected>' + s + '</option>';
      else
        sel_string += ' <option>' + s + '</option>';
    })
    sel_string += "</select>";
    return sel_string;
  }

  function input_tag(id,value){
    input_string = '<input type=text id=filter_value_' + id + ' name=filter_value_' + id;
    input_string += ' class=filter_value_input ';
    if (value != '')
      input_string += 'value=' + value;
    input_string += ' </input>';
    return input_string;
  }
