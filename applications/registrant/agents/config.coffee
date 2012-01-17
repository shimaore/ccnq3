do ->
    base_path = "./opensips"
    model = 'registrant'

    params = {}
    for _ in ['default.json',"#{model}.json"]
      do (_) ->
        data = JSON.parse fs.readFileSync "#{base_path}/#{_}"
        params[k] = data[k] for own k of data

    # params[k] = p.opensips[k] for own k of p.opensips

    params.opensips_base_lib = base_path

    require("#{base_path}/compiler.coffee") params
