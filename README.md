# Raspi Firewall Tester

Ever had an app installed on your work computer behind a corporate firewall, which you had trouble identifying the ports and destination addresses that needed to be whitelisted in order for the app to run properly? This tool would be extremely useful in those situations where the security team may need evidence of which ports and destination addresses need to be open.

The Raspberry Pi can act as a NAT router, which is commonly found in most homes but without the extra fluff. In this case, the NAT network would be configured to `DROP` outgoing packets by default, meaning a global blacklist is established, and individual exceptions would have to be made. This is typically how some strict corporate firewall works.




