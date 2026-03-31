unit Auth.Model;

interface

type
  TAuthUser = class
  private
    FId: Int64;
    FLogin: string;
    FNome: string;
    FSenhaHash: string;
    FAtivo: string;
    FBloqueado: string;
  public
    property Id: Int64 read FId write FId;
    property Login: string read FLogin write FLogin;
    property Nome: string read FNome write FNome;
    property SenhaHash: string read FSenhaHash write FSenhaHash;
    property Ativo: string read FAtivo write FAtivo;
    property Bloqueado: string read FBloqueado write FBloqueado;
  end;

implementation

end.
