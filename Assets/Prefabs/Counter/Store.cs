using UdonSharp;
using VRC.SDKBase;

public class Store : Notifyer
{
    [UdonSynced(UdonSyncMode.None)]
    private int _count = 0;

    public int count
    {
        get
        {
            return _count;
        }
    }

    // MasterClient から同期されたときに発火する
    public override void OnDeserialization()
    {
        Notify();
    }
    // プレイヤーが入室したときに発火する
    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        if (player.IsOwner(gameObject))
        {
            RequestSerialization();
        }
    }

    public void TransferOwner()
    {
        var player = Networking.LocalPlayer;
        if (!player.IsOwner(gameObject))
        {
            Networking.SetOwner(player, gameObject);
        }

        Notify();
    }

        public void Increment()
    {
        var player = Networking.LocalPlayer;
        if (player.IsOwner(gameObject))
        {
            RemoteIncrement();
        }
        else
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, nameof(RemoteIncrement));
        }
    }


    public void Decrement()
    {
        var player = Networking.LocalPlayer;
        if (player.IsOwner(gameObject))
        {
            RemoteDecrement();
        }
        else
        {
            SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, nameof(RemoteDecrement));
        }
    }

    public void RemoteIncrement()
    { 
        _count++;
        RequestSerialization();
        Notify();
    }

    public void RemoteDecrement()
    {
        _count--;
        RequestSerialization();
        Notify();
    }
}
