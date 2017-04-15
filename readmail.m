%% READMAIL
% A simple script highlighting how you can connect to Outlook and
% import emails, including their subjects, bodies & attachements
%
% David Willingham, November 9 2011, MathWorks Australia

function [body] = readmail()

%% Connecting to Outlook
outlook = actxserver('Outlook.Application');
mapi=outlook.GetNamespace('mapi');
INBOX=mapi.GetDefaultFolder(6);

%% Retrieving last email
count = INBOX.Items.Count; %index of the most recent email.
firstemail=INBOX.Items.Item(count); %imports the most recent email
subject = firstemail.get('Subject');
body = firstemail.get('Body');

