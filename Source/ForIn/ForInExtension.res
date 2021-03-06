        ��  ��                  �  @   ��
 F O R I N B A S E C L A S S E S         0         {$IFDEF CONDITIONALEXPRESSIONS}
 {$IF CompilerVersion >= 18.0}
  {$DEFINE SUPPORTS_INLINE}
 {$IFEND}
{$ENDIF}

type
  {$IFDEF CLR}
  zzForInBaseEnumeratorIterator = class(TObject);
  {$ELSE}
  zzForInMoveNextMethod = function: Boolean of object;

  zzForInFinallyBlock = packed record
    PrevExceptionBlock: Pointer;
    JumpAddr: Pointer;
    SavedEBP: Pointer;
  end;

  zzForInBaseEnumeratorIterator = class(TObject)
  private
    FFinished: Boolean;
    FMoveNext: zzForInMoveNextMethod;
    FOrgFinallyProc: Pointer;
    FOrgSavedEBP: Pointer;
  public
    constructor Create(AMoveNext: zzForInMoveNextMethod);
    destructor Destroy; override;
    function TryFinally: Boolean;
  end;
  {$ENDIF CLR}

{$IFNDEF CLR}
constructor zzForInBaseEnumeratorIterator.Create(AMoveNext: zzForInMoveNextMethod);
begin
  FMoveNext := AMoveNext;
end;

destructor zzForInBaseEnumeratorIterator.Destroy;
begin
  TObject(TMethod(FMoveNext).Data).Free;
end;

function zzForInBaseEnumeratorIterator.TryFinally: Boolean;
asm
  xor edx, edx
  mov ecx, fs:[edx]

  mov dl, [eax].zzForInBaseEnumeratorIterator.FFinished
  test dl, dl
  jnz @@Finished
  mov [eax].zzForInBaseEnumeratorIterator.FFinished, 1 // set ExceptionHook to True

  // backup the previous exception frame
  mov edx, [ecx].zzForInFinallyBlock.JumpAddr
  mov [eax].zzForInBaseEnumeratorIterator.FOrgFinallyProc, edx
  mov edx, [ecx].zzForInFinallyBlock.SavedEBP
  mov [eax].zzForInBaseEnumeratorIterator.FOrgSavedEBP, edx

  // replace the exception handler
  mov edx, OFFSET @@LocalHandleFinally
  mov [ecx].zzForInFinallyBlock.JumpAddr, edx
  mov [ecx].zzForInFinallyBlock.SavedEBP, eax // redirect SavedEBP to Self

  mov al, 1 // return True
  ret
@@Finished:
  // restore previous exception frame
  mov edx, [eax].zzForInBaseEnumeratorIterator.FOrgSavedEBP
  mov [ecx].zzForInFinallyBlock.SavedEBP, edx
  mov edx, [eax].zzForInBaseEnumeratorIterator.FOrgFinallyProc
  mov [ecx].zzForInFinallyBlock.JumpAddr, edx

  call Free
  xor eax, eax // return False
  ret

@@LocalHandleFinally:
  push edx
  push ecx

  xor edx, edx
  mov ecx, fs:[edx]
  mov ecx, [ecx]
  mov eax, [ecx].zzForInFinallyBlock.SavedEBP // Self

  // restore exception frame
  mov edx, [eax].zzForInBaseEnumeratorIterator.FOrgSavedEBP
  mov [ecx].zzForInFinallyBlock.SavedEBP, edx
  mov edx, [eax].zzForInBaseEnumeratorIterator.FOrgFinallyProc
  mov [ecx].zzForInFinallyBlock.JumpAddr, edx

  // free enumeration objects
  push edx
  call Free
  pop eax

  pop ecx
  pop edx
  jmp eax
end;
{$ENDIF ~CLR}


type
  zzForInBaseEnumeratorArrayIterator = {$IFDEF CLR}class{$ELSE}object{$ENDIF}
    Index: Integer;
    Count: Integer;
    function MoveNext: Boolean; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
  end;

function zzForInBaseEnumeratorArrayIterator.MoveNext: Boolean;
begin
  Inc(Index);
  Result := Index < Count;
end;
