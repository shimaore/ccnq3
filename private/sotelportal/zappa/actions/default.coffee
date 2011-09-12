@include = ->
  css '/p/style.css': ->
    '''
    label.normal {
      margin: 6px;
      width: 40%;
      display: inline-block;
    }
    label.normal:before {
      display: block;
      content: "\00a0"; /* NBSP */
      width: 0;
      height: 0;
    }
    label.error {
      background: red;
      color: white;
    }
    input,select {
      /* width: 50%; */
      display: inline-block;
      border: thin solid;
    }
    div.form {
      padding: 10px;
      border: solid black 1px;
    }
    '''

