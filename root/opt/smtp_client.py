#!/usr/bin/python3
# -*- coding: utf-8 -*-

# System imports
import argparse
import email.mime.text
import json
import smtplib
import sys


# MAIN
if __name__ == '__main__':

    def HeaderMap(arg):
        if not isinstance(arg, str) or '=' not in arg:
            raise argparse.ArgumentError('header value must be in the form NAME=VALUE')
        name, value = arg.split('=')
        return (name, value)


    # create parser for cli options
    parser = argparse.ArgumentParser(description="SMTP client",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    # transport arguments
    parser.add_argument('--host', dest='host',
                        default='localhost',
                        help='Set the mta host address')
    parser.add_argument('--port', dest='port', type=int,
                        default=25,
                        help='Set the mta port')
    parser.add_argument('--timeout', dest='timeout', type=int,
                        default=5,
                        help='Set the smtp timeout')
    parser.add_argument('--user', dest='user',
                        help='Set the smtp username and password <USER:PASSWORD>')

    secure_group = parser.add_mutually_exclusive_group()
    secure_group.add_argument('--starttls', dest='starttls',
                              action='store_true', default=False,
                              help='Enable starttls mode')
    secure_group.add_argument('--ssl', dest='ssl',
                              action='store_true', default=False,
                              help='Enable ssl mode')

    # email arguments
    parser.add_argument('-f', '--from', dest='from',
                        default='noreply@localhost',
                        help='Set the sender address')
    parser.add_argument('recipients', type=str,
                        action='append', default=[],
                        help='Set email recipients')
    parser.add_argument('--body', dest='body', type=str,
                        default='',
                        help='Set email body')
    parser.add_argument('-s', '--subject', dest='subject', type=str,
                        required=True,
                        help='Set email subject')
    parser.add_argument('--header', dest='headers', type=HeaderMap,
                        action='append', default=[],
                        help='Add theses customs headers to mail')

    parser.add_argument('--verbose', '-v', dest='verbose', default=0,
                        action='count',
                        help='Increase verbosity level (0-2)')

    args = parser.parse_args()
    if args.verbose > 0:
        print('launch with args %s', json.dumps(vars(args)))

    if not args.recipients:
        parser.error('you need to set at least one recipient')
    if args.user:
        if not ':' in args.user:
            parser.error('--user must be in the form user:password')

    msg = email.mime.text.MIMEText(args.body)
    msg['Subject'] = args.subject
    msg['From'] = getattr(args, 'from')
    msg['To'] = ','.join(args.recipients)
    for k,v in args.headers:
        msg[k] = v

    try:
        # smtp connection
        if args.ssl:
            smtpConn = smtplib.SMTP_SSL(host=args.host, port=args.port, timeout=args.timeout)
        else:
            smtpConn = smtplib.SMTP(host=args.host, port=args.port, timeout=args.timeout)
        smtpConn.ehlo_or_helo_if_needed()
        if args.starttls:
            if not smtpConn.has_extn("starttls"):
                raise smtplib.SMTPException('mta does not support STARTTLS')
            smtpConn.starttls()

        if args.user:
            user_parts = args.user.split(':')
            smtpConn.login(user_parts[0], user_parts[1])

        smtpConn.sendmail(getattr(args, 'from'), args.recipients, msg.as_string())

        smtpConn.quit()
        print('Successfully sent email')
        sys.exit(0)
    except smtplib.SMTPException as ex:
        print('Error: unable to send email because of {}'.format(str(ex)))
        sys.exit(1)
