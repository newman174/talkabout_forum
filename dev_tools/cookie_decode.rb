# cookie_decode.rb

# rubocop:disable all

require 'rack'
# require 'rack'
require 'base64'

# puts Base64.decode64(Rack::Utils.unescape("BAh7C0kiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTNhNzJkMDY5NzIzMjVmMmYwMzYzYjQxZTc2YTExYjRmNDY2NDY1ZjFmNzNhNzk5YjAwNDJmMTlmYThlNTI2BjsARkkiCWNzcmYGOwBGSSIxRmt1eDJHOXRnZEEwamthQ1RvZ1VMYV9kNllob0dzeFdrRlBMOUtpTmJxbz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZmRmZGUzNmJlNGVhMmUzZjEzYjEwYTkxODQyNTIwYWY3ODdhOWVlMAY7AEZJIgpsaW1pdAY7AEZpCkkiDXVzZXJuYW1lBjsARkkiCm5ld21zBjsAVEkiDHVzZXJfaWQGOwBGaQY=--73870104a30b0dc89e9e8522805b32ee9d5edcc0".split('--').first))

# puts Base64.decode64(
#   Rack::Utils.unescape(
#     "BAh7C0kiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTNhNzJkMDY5NzIzMjVmMmYwMzYzYjQxZTc2YTExYjRmNDY2NDY1ZjFmNzNhNzk5YjAwNDJmMTlmYThlNTI2BjsARkkiCWNzcmYGOwBGSSIxRmt1eDJHOXRnZEEwamthQ1RvZ1VMYV9kNllob0dzeFdrRlBMOUtpTmJxbz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZmRmZGUzNmJlNGVhMmUzZjEzYjEwYTkxODQyNTIwYWY3ODdhOWVlMAY7AEZJIgpsaW1pdAY7AEZpCkkiDXVzZXJuYW1lBjsARkkiCm5ld21zBjsAVEkiDHVzZXJfaWQGOwBGaQY%3D--73870104a30b0dc89e9e8522805b32ee9d5edcc0"
#     .split('--').first
#   )
# )

def unescape(cookie)
  Rack::Utils.unescape(cookie.split('--').first)
end

def decode_cookie(cookie)
  Base64.decode64(unescape(cookie))
end

cookie = "BAh7C0kiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTNhNzJkMDY5NzIzMjVmMmYwMzYzYjQxZTc2YTExYjRmNDY2NDY1ZjFmNzNhNzk5YjAwNDJmMTlmYThlNTI2BjsARkkiCWNzcmYGOwBGSSIxRmt1eDJHOXRnZEEwamthQ1RvZ1VMYV9kNllob0dzeFdrRlBMOUtpTmJxbz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZmRmZGUzNmJlNGVhMmUzZjEzYjEwYTkxODQyNTIwYWY3ODdhOWVlMAY7AEZJIgpsaW1pdAY7AEZpCkkiDXVzZXJuYW1lBjsARkkiCm5ld21zBjsAVEkiDHVzZXJfaWQGOwBGaQY%3D--73870104a30b0dc89e9e8522805b32ee9d5edcc0"

cookie_url_decoded = "BAh7C0kiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTNhNzJkMDY5NzIzMjVmMmYwMzYzYjQxZTc2YTExYjRmNDY2NDY1ZjFmNzNhNzk5YjAwNDJmMTlmYThlNTI2BjsARkkiCWNzcmYGOwBGSSIxRmt1eDJHOXRnZEEwamthQ1RvZ1VMYV9kNllob0dzeFdrRlBMOUtpTmJxbz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZmRmZGUzNmJlNGVhMmUzZjEzYjEwYTkxODQyNTIwYWY3ODdhOWVlMAY7AEZJIgpsaW1pdAY7AEZpCkkiDXVzZXJuYW1lBjsARkkiCm5ld21zBjsAVEkiDHVzZXJfaWQGOwBGaQY=--73870104a30b0dc89e9e8522805b32ee9d5edcc0"

encrypted_cookie = 'vkOsS1CUKDV3Mcp6psfjbZAiN2y9s0l2RRrXNV00O36VvUHdjPHmRLhwrFtVObx2H6YqaNX5R6nBV5mfGPmzqCdWqQKBDgAy0SC3dhs3UlU%2FyIo14QLyfDQPeCuJANMl9G11fRicJwMv2TxBjT0wavolAZTi9sJ3ijap8%2B%2BwE8yonNRdi6Y3lnruSQFOvBgVxhRpSGfKyDTmlpUPO7BxswOcbZoAQJRBGGeMRW%2BuWCQ%3D'
# puts decode_cookie(cookie)
# puts
# puts decode_cookie(cookie_url_decoded)
# puts
# puts decode_cookie(encrypted_cookie)
# puts decode_cookie(cookie) == decode_cookie(cookie_url_decoded)

# puts decode_cookie('rack.session=BAh7CkkiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTg1NzViYmFkZWRjYTk1OGYzZWM2ZDA4NThhYjA3ZjY5OGFhZjliYjMwYzAxMWI4NjBmN2NlMmFkZTQ5NTM0BjsARkkiCWNzcmYGOwBGSSIxbWU1VlM5WENUUWVUcUNMMU9CWTZZZm1iSzMxMXFYMHozUlNweVN3NjQxYz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZGEzOWEzZWU1ZTZiNGIwZDMyNTViZmVmOTU2MDE4OTBhZmQ4MDcwOQY7AEZJIgpsaW1pdAY7AEZpD0kiCmVycm9yBjsARkkiJllvdSBtdXN0IGJlIHNpZ25lZCBpbiB0byBkbyB0aGF0LgY7AFQ%3D--f7958900b6e782ea7c2634c2e983ae4c9bcaa1f1')

# puts decode_cookie('BAh7CkkiD3Nlc3Npb25faWQGOgZFVG86HVJhY2s6OlNlc3Npb246OlNlc3Npb25JZAY6D0BwdWJsaWNfaWRJIkU1MTg1NzViYmFkZWRjYTk1OGYzZWM2ZDA4NThhYjA3ZjY5OGFhZjliYjMwYzAxMWI4NjBmN2NlMmFkZTQ5NTM0BjsARkkiCWNzcmYGOwBGSSIxbWU1VlM5WENUUWVUcUNMMU9CWTZZZm1iSzMxMXFYMHozUlNweVN3NjQxYz0GOwBGSSINdHJhY2tpbmcGOwBGewZJIhRIVFRQX1VTRVJfQUdFTlQGOwBUSSItZGEzOWEzZWU1ZTZiNGIwZDMyNTViZmVmOTU2MDE4OTBhZmQ4MDcwOQY7AEZJIgpsaW1pdAY7AEZpD0kiCmVycm9yBjsARkkiJllvdSBtdXN0IGJlIHNpZ25lZCBpbiB0byBkbyB0aGF0LgY7AFQ%3D--f7958900b6e782ea7c2634c2e983ae4c9bcaa1f1')


# puts decode_cookie('fVsisqfyHpULpUJwXkQ7Hjnp8w68a48oKm5Kt9jgcwt6d6erZJsaxa9ivH2ot8spRJ8LPT0J5VRI6xVdPn3%2B7DC15T0TXQ%2BfEBtBG7N6S3p6OfiD16deNxKCW9lV5OqbKLV7mRU4GQzu09dXjxKeSsMr7GqnVIXBWh5WVGY09KotpeeAokod1L0CAytF0RDWoU0wMNjw%2B%2B43fDKko%2Fa24D1oJ2%2FPmTKiNT8Viy4nRkM%3D')
puts 'hi world'
puts decode_cookie("HuzdIzRR9tYO2SR9wvUyzH6OGZ5OBJM790dkauRUG4sJ9Ncau7juQMUPBpVjw8TL0S5w1BP9S0vipPIFoA9kDAx%2Btcg63a3mhR%2Bjz6wUE1xNU8DVYhszJ9uXB8VGwnfLQGCv86baCJVkWRpMJMgjV4MMCFEPjGJdjsxK5FfTRDA4bTx0ApQE%2BkpP3FIGRwa9I%2B9ZFaaDuTwpggMLlOZuZEINdTpJOIpHYFHGTW4NOOAr279fpK5gDP5r21gp%2Fr%2F1OXZwggCbEjdTu42kdXaX5Xm%2FVUYizIGxGOAx5vGsnzi2B8cik6oj5iTdXb4GSX8m")

# rubocop:enable all
