require 'open-uri'

# if it raises 'SSL_connect returned=1 errno=0 state=error:
# certificate verify failed (unable to get local issuer certificate)
# (OpenSSL::SSL::SSLError)', SSL_CERT_FILE env var is unset
URI.open('https://www.google.com')
