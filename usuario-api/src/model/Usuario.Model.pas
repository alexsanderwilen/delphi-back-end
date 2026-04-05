unit Usuario.Model;

interface

type
  TUsuario = class
  private
    FId: Int64;
    FLogin: string;
    FNome: string;
    FEmail: string;
    FAtivo: string;
    FFotoPath: string;
    FFotoUrl: string;
  public
    property Id: Int64 read FId write FId;
    property Login: string read FLogin write FLogin;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Ativo: string read FAtivo write FAtivo;
    property FotoPath: string read FFotoPath write FFotoPath;
    property FotoUrl: string read FFotoUrl write FFotoUrl;
  end;

implementation

end.
