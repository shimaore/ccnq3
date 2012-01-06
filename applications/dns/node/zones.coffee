instances =
  szafa: "89.79.65.106"
  micro: "79.125.35.132"
  e24: "178.216.201.182"

module.exports =
  "appload.pl":
    admin: "rav.appload.pl"
    records: [
      {class: "NS", value: "dns1.appload.pl."}
      {class: "NS", value: "dns2.appload.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}
      
      {class: "A", value: instances.micro}
        
      {class: "MX", value: "10 aspmx.l.google.com."}
      {class: "MX", value: "20 alt1.aspmx.l.google.com."}
      {class: "MX", value: "20 alt2.aspmx.l.google.com."}
      {class: "MX", value: "30 aspmx2.googlemail.com."}
      {class: "MX", value: "30 aspmx3.googlemail.com."}
      {class: "MX", value: "30 aspmx4.googlemail.com."}
      {class: "MX", value: "30 aspmx5.googlemail.com."}
      {class: "TXT", value: "google-site-verification=gGDp__umqNYAZmtbyCHtkNhUsGr-Me_V2m6Ztf3C1_4"}
      {class: "NAPTR", value: [10,100,'u','E2U+sip','!^.*$!sip:info@example.com!']}
      
      {prefix: "s0", value: instances.szafa}
      {prefix: "s1", value: instances.micro}
      {prefix: "videogallery", value: instances.micro}
      {prefix: "videoportal", value: instances.micro}
      {prefix: "mysql", value: instances.micro}
      {prefix: "db", value: instances.micro}
      {prefix: "s2", class: "CNAME", value: "anj86.neoplus.adsl.tpnet.pl."}
      {prefix: "s3", value: instances.e24}
      {prefix: "notatki", value: instances.e24}
    ]
  "eldesign.eu":
    admin: "maciek@appload.pl"
    records: [  
      {class: "NS", value: "dns1.appload.pl."}
      {class: "NS", value: "dns2.appload.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}
      
      {class: "A", value: instances.szafa}
        
      {class: "MX", value: "1	aspmx.l.google.com."}
      {class: "MX", value: "5	alt1.aspmx.l.google.com."}
      {class: "MX", value: "10 aspmx2.googlemail.com."}    
      {class: "MX", value: "10 aspmx3.googlemail.com."}
      {class: "TXT", value: "google-site-verification=2QnLKuCcHNXwtQVx-lkcKtZgR_1db62839MSKf1cDIM"}
    ]
  "fotowrocek.pl":
    admin: "maciek@appload.pl"
    records: [
      {class: "NS", value: "dns1.fotowrocek.pl."}
      {class: "NS", value: "dns2.fotowrocek.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}
        
      {class: "A", value: instances.szafa}
        
      {class: "MX", value: "10 mail"}
    ]
  "maciek.wroclaw.pl":
    admin: "maciek@appload.pl"
    records: [
      {class: "NS", value: "dns1.maciek.wroclaw.pl."}
      {class: "NS", value: "dns2.maciek.wroclaw.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}
        
      {class: "A", value: instances.szafa}
      {class: "MX", value: "10 mail"}
    ]
  "vroc.pl":
    admin: "maciek@appload.pl"
    records: [
      {class: "NS", value: "dns1.vroc.pl."}
      {class: "NS", value: "dns2.vroc.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}
      
      {class: "A", value: instances.szafa}
      
      {class: "MX", value: "10 aspmx.l.google.com."}
      {class: "MX", value: "20 alt1.aspmx.l.google.com."}
      {class: "MX", value: "20 alt2.aspmx.l.google.com."}
      {class: "MX", value: "30 aspmx2.googlemail.com."}
      {class: "MX", value: "30 aspmx3.googlemail.com."}
      {class: "MX", value: "30 aspmx4.googlemail.com."}
      {class: "MX", value: "30 aspmx5.googlemail.com."}
      {class: "TXT", value: "google-site-verification=oB5fviSOZpxfQRV0h6NkMnWNJyDCP-7csddObT-nIQM"}
      
      {prefix: "targowa", value: "91.196.50.43"}
      {prefix: "dom", value: "89.228.170.124"}
      {prefix: "koliber", value: instances.micro}
    ]
  "zaqpki.pl":
    admin: "rav@appload.pl"
    records: [
      {class: "NS", value: "dns1.zaqpki.pl."}
      {class: "NS", value: "dns2.zaqpki.pl."}
      {prefix: "dns1", value: instances.micro}
      {prefix: "dns2", value: instances.szafa}

      {class: "A", value: instances.micro}
    ]
