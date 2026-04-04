program UsuarioApi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Horse.CORS,
  Horse.JWT,
  uConnection.Config in '..\shared\connection\uConnection.Config.pas',
  uConnection.Factory in '..\shared\connection\uConnection.Factory.pas',
  Usuario.Model in 'src\model\Usuario.Model.pas',
  Usuario.DTO in 'src\dto\Usuario.DTO.pas',
  Usuario.Repository in 'src\repository\Usuario.Repository.pas',
  Usuario.Controller in 'src\controller\Usuario.Controller.pas',
  Usuario.Service in 'src\service\Usuario.Service.pas',
  uPassword.Hash in '..\shared\auth\uPassword.Hash.pas',
  uJWT.Helper in '..\shared\auth\uJWT.Helper.pas',
  Auth.DTO in 'src\dto\Auth.DTO.pas',
  Auth.Model in 'src\model\Auth.Model.pas',
  Auth.Repository in 'src\repository\Auth.Repository.pas',
  Auth.Service in 'src\service\Auth.Service.pas',
  Auth.Controller in 'src\controller\Auth.Controller.pas',
  uJWT.Middleware in '..\shared\auth\uJWT.Middleware.pas',
  uApp.Exception in '..\shared\response\uApp.Exception.pas',
  uException.Handler in '..\shared\middleware\uException.Handler.pas',
  uJWT.CurrentUser in '..\shared\auth\uJWT.CurrentUser.pas',
  uResponse.Helper in '..\shared\response\uResponse.Helper.pas';

begin
   try
    THorse.Use(Jhonson);
    THorse.Use(CORS);
    THorse.Use(ExceptionMiddleware);

    TConnectionFactory.Configure;

    Auth.Controller.Registry;
    Usuario.Controller.Registry;

    THorse.Listen(9000,
      procedure
      begin
        Writeln('Servidor rodando em http://localhost:9000');
      end);

  except

    on E: Exception do
      Writeln(E.ClassName + ': ' + E.Message);
  end;
end.
