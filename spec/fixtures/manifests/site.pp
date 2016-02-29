node 'computer1.mycompany.com' {
  notify{"computer1":}
}

node 'computer2.mycompany.com' {
  notify{"computer2":}
}

node /\w*[3-6]{1}\w*/ {
  notify{"computer3-6":}
}

node default {
  notify{"default":}
}
