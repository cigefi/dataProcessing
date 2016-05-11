function [status] = mailsender(to,subject,message)
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','E_mail','cigefi.ucr.dev');
    setpref('Internet','SMTP_Username','cigefi.ucr.dev');
    setpref('Internet','SMTP_Password','wonanuk.cigefi');
    props=java.lang.System.getProperties;
    pp=props.setProperty('mail.smtp.auth','true'); %#ok
    pp=props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory'); %#ok
    pp=props.setProperty('mail.smtp.socketFactory.port','465'); %#ok
    try
        sendmail(to,subject,message)
        status = true;
    catch %e
        % disp(e.message);
        status = false;
    end
end